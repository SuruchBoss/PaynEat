import { env } from '../../config/env.js';
import { isEnabled, toLogRecord } from './logRecord.js';
import { currentRequestContext, PROCESS_CORRELATION_ID } from './requestContext.js';

/** ค่า label `app` ของ backend POS ตามสัญญา telemetry */
export const APP_NAME = 'payneat-pos-api';

/**
 * สัญญาบังคับ label `event` ทุกบรรทัด แต่แคตตาล็อก event ยังไม่มี event ของวงจรชีวิตเซิร์ฟเวอร์ (เปิด/ปิด,
 * migrate, ตาชั่ง) บรรทัดพวกนี้จึงใช้ค่าเดียวกันหมด — ค่าเดียวกับ PaynEat ERP ไม่ตั้งชื่อ event ขึ้นเอง
 */
export const GENERIC_EVENT = 'app.log';

const stdoutSink = (line) => process.stdout.write(`${line}\n`);

// ตอนรันเทสต์ไม่เขียนออก stdout (เหมือนที่เคยปิด log ของคำขอตอนเทสต์) — เทสต์ที่ตรวจ log ตั้ง sink ของตัวเองแทน
let sink = env.isTest ? () => {} : stdoutSink;

/** เปลี่ยนปลายทางของ log (เทสต์ใช้เก็บบรรทัดไว้ตรวจ) คืน sink เดิมไว้ให้คืนค่าได้ */
export const setLogSink = (next) => {
  const previous = sink;
  sink = next;
  return previous;
};

/**
 * เขียน log หนึ่งบรรทัด — correlation id, trace และสาขา มาจากบริบทของคำขอที่กำลังทำอยู่ถ้าไม่ได้ส่งมาเอง
 * `labels` ใส่ได้เฉพาะ label ในสัญญา (`document_number`, `rule`, `reason`, …) ห้ามใส่ข้อมูลส่วนบุคคล
 */
export const writeLog = ({
  severity,
  message,
  event = GENERIC_EVENT,
  labels = {},
  correlationId,
  traceId,
  locationCode,
  httpRequest,
  error,
}) => {
  const { logLevel, logFormat, gcpProject } = env.telemetry;
  if (!isEnabled(logLevel, severity)) return;

  const context = currentRequestContext();
  const record = toLogRecord(
    {
      severity,
      time: new Date(),
      message,
      labels: {
        ...labels,
        app: APP_NAME,
        event,
        correlation_id: correlationId ?? context?.correlationId ?? PROCESS_CORRELATION_ID,
        location_code: locationCode ?? context?.locationCode,
      },
      traceId: traceId ?? context?.traceId,
      httpRequest,
      error,
    },
    { format: logFormat, gcpProject, includeStack: logLevel === 'DEBUG' },
  );
  sink(JSON.stringify(record));
};

const at =
  (severity) =>
  (message, fields = {}) =>
    writeLog({ ...fields, severity, message });

export const logger = {
  debug: at('DEBUG'),
  info: at('INFO'),
  notice: at('NOTICE'),
  warning: at('WARNING'),
  error: at('ERROR'),
  critical: at('CRITICAL'),
};

export default logger;
