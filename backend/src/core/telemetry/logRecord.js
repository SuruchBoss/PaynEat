// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/**
 * รูปร่างของ log หนึ่งบรรทัดตามสัญญา telemetry v1.1 ของระบบนิเวศ PaynEat
 * (https://github.com/SuruchBoss/PaynEat-ERP/blob/main/docs/TELEMETRY.md, ticket 24)
 *
 * pure function ล้วน ไม่มี I/O ไม่อ่านนาฬิกาเอง — ทุกอย่างที่สัญญากำหนดให้ตรวจได้ (ชื่อ severity,
 * รูปแบบ latency, x-request-id แบบไหนรับได้, labels/trace อยู่ที่ key ไหนในแต่ละรูปแบบ) ตัดสินที่นี่ที่
 * เดียว เทสต์ได้ด้วยตัวอย่างที่ตรวจด้วยมือได้ และไม่เพี้ยนไปตามจุดที่เรียกใช้ ตรรกะเดียวกับ
 * PaynEat ERP `core/telemetry/domain/log-record.ts` เพื่อให้ query ชุดเดียวใช้ได้ทั้งสองระบบ
 */

export const SEVERITIES = ['DEBUG', 'INFO', 'NOTICE', 'WARNING', 'ERROR', 'CRITICAL'];

const RANK = Object.fromEntries(SEVERITIES.map((severity, i) => [severity, (i + 1) * 100]));

/** บรรทัดระดับ `severity` ถูกเขียนไหมเมื่อตั้ง LOG_LEVEL ไว้ที่ `threshold` */
export const isEnabled = (threshold, severity) => RANK[severity] >= RANK[threshold];

/**
 * severity ของ `http.request.completed`: `INFO`; `WARNING` สำหรับ 4xx ยกเว้น 401 และ 404; `ERROR`
 * สำหรับ 5xx — 401/404 คือ API ทำงานตามที่ออกแบบ (token หมดอายุ, หาไม่เจอ) ไม่ใช่ความผิดพลาดที่ต้องเตือน
 */
export const severityForStatus = (status) => {
  if (status >= 500) return 'ERROR';
  if (status >= 400 && status !== 401 && status !== 404) return 'WARNING';
  return 'INFO';
};

/** `231.4` ms → `"0.231s"` — Cloud Logging ปฏิเสธตัวเลขใน `httpRequest.latency` */
export const formatLatency = (milliseconds) => `${(Math.max(0, milliseconds) / 1000).toFixed(3)}s`;

/** `/orders/7?search=x` → `/orders/7` — query string พกอะไรมาก็ได้ จึงไม่มีวันถึง log */
export const requestPath = (url) => {
  const cut = url.search(/[?#]/);
  return cut === -1 ? url : url.slice(0, cut);
};

/**
 * ส่วนของ path ที่เป็นความลับ แทนด้วยชื่อพารามิเตอร์ก่อนเขียนลง log — QR token ของโต๊ะ (ticket 17) ใครได้
 * ไปก็สั่งอาหารเข้าโต๊ะนั้นได้ จึงนับเป็น token ตามรายการ "ห้ามอยู่ใน log" ของสัญญา ใช้กับทุกคำขอใต้ path
 * นี้ ไม่ว่าจะเจอ route หรือไม่ (ลิงก์ที่ถูกตัด/พิมพ์ผิดก็ยังมี token จริงอยู่ครึ่งหนึ่ง)
 */
const SECRET_PATH_SEGMENTS = [[/^(\/api\/v1\/public\/tables\/)[^/]+/, '$1:qrToken']];

export const redactPath = (path) =>
  SECRET_PATH_SEGMENTS.reduce(
    (out, [pattern, replacement]) => out.replace(pattern, replacement),
    path,
  );

const REQUEST_ID = /^[\w-]{8,64}$/;

/** `x-request-id` ของผู้เรียกถ้าตรง `^[\w-]{8,64}$` — ไม่ตรงคืน undefined แล้วผู้เรียกได้รหัสใหม่แทน */
export const acceptRequestId = (incoming) =>
  typeof incoming === 'string' && REQUEST_ID.test(incoming) ? incoming : undefined;

const TRACEPARENT = /^[\da-f]{2}-([\da-f]{32})-[\da-f]{16}-[\da-f]{2}$/;

/**
 * trace id จาก header W3C `traceparent` หรือ undefined — trace id ที่เป็นศูนย์ทั้งหมดผิดสเปก W3C
 * จึงทิ้งไป ไม่ส่งต่อ (ticket 24 ส่งต่อ trace ที่มีมาเท่านั้น ไม่สร้าง span เอง)
 */
export const parseTraceparent = (header) => {
  if (typeof header !== 'string') return undefined;
  const match = TRACEPARENT.exec(header.trim().toLowerCase());
  if (!match || /^0+$/.test(match[1])) return undefined;
  return match[1];
};

/** รหัสสถานที่กลางของระบบนิเวศ (รูปแบบเดียวกับ ticket 25) — รหัสสาขาที่ไม่ตรงรูปแบบไม่ถูกใส่เป็น label */
const LOCATION_CODE = /^[A-Z0-9][A-Z0-9-]{1,31}$/;

export const isLocationCode = (code) => typeof code === 'string' && LOCATION_CODE.test(code);

const GCP_LABELS = 'logging.googleapis.com/labels';
const GCP_TRACE = 'logging.googleapis.com/trace';

/** ทิ้ง label ที่ไม่เกี่ยวข้อง แทนที่จะเขียน undefined หรือข้อความว่าง */
const cleanLabels = (labels) =>
  Object.fromEntries(
    Object.entries(labels).filter(([, value]) => typeof value === 'string' && value.length > 0),
  );

/**
 * object JSON ของ log หนึ่งบรรทัด
 *
 * `default`: `labels` และ `trace` เป็น key ธรรมดา ไม่มีชื่อ vendor ใดๆ (POS ต้อง self-host ได้)
 * `gcp`: labels object เดียวกันอยู่ใต้ `logging.googleapis.com/labels` และ trace เป็น
 * `projects/<project>/traces/<id>` ใต้ `logging.googleapis.com/trace` — ถ้าไม่ได้ตั้ง project id ก็ไม่มี
 * resource name ที่ถูกต้องให้เขียน จึงคง trace ไว้ที่ key ธรรมดา ดีกว่าเขียนรูปแบบที่ Cloud Logging อ่านผิด
 *
 * @param {{severity: string, time: Date, message: string, labels: Record<string, string|undefined>,
 *   traceId?: string, httpRequest?: object, error?: {type: string, message: string, stack?: string}}} entry
 * @param {{format: 'default'|'gcp', gcpProject?: string, includeStack: boolean}} options
 */
export const toLogRecord = (entry, options) => {
  const record = {
    severity: entry.severity,
    time: entry.time.toISOString(),
    message: entry.message,
  };

  const labels = cleanLabels(entry.labels);
  if (options.format === 'gcp') record[GCP_LABELS] = labels;
  else record.labels = labels;

  if (entry.traceId) {
    if (options.format === 'gcp' && options.gcpProject) {
      record[GCP_TRACE] = `projects/${options.gcpProject}/traces/${entry.traceId}`;
    } else {
      record.trace = entry.traceId;
    }
  }

  if (entry.httpRequest) record.httpRequest = { ...entry.httpRequest };

  if (entry.error) {
    record.error = {
      type: entry.error.type,
      message: entry.error.message,
      ...(options.includeStack && entry.error.stack ? { stack: entry.error.stack } : {}),
    };
  }

  return record;
};
