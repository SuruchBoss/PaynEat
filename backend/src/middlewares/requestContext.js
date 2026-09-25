import { randomUUID } from 'node:crypto';
import {
  acceptRequestId,
  formatLatency,
  parseTraceparent,
  redactPath,
  requestPath,
  severityForStatus,
} from '../core/telemetry/logRecord.js';
import { writeLog } from '../core/telemetry/logger.js';
import { observeRequest } from '../core/telemetry/metrics.js';
import { runWithRequestContext } from '../core/telemetry/requestContext.js';

/** ที่ที่ errorHandler ฝากรายละเอียดความผิดพลาด 5xx ไว้ให้บรรทัด `http.request.completed` รายงาน */
export const RESPONSE_ERROR = 'telemetryError';

/** label `route` ของคำขอที่ไม่เข้า mount/route ไหนเลย — path สุ่มจากภายนอกจึงเพิ่มจำนวน series ไม่ได้ */
export const UNMATCHED_ROUTE = 'unmatched';

/**
 * route template ของคำขอ จำไว้ตอนที่ Express ตั้ง `req.route` เพราะตอนนั้น `req.baseUrl` ยังเป็น mount ของ
 * router ที่ route นั้นอยู่ — ถ้ารอคำนวณตอน response เสร็จ คำขอที่ error ไหลออกจาก router ย่อยจะได้ baseUrl
 * ที่ Express คืนค่ากลับไปแล้ว (`/:id` แทน `/api/v1/orders/:id`)
 *
 * คำขอที่จบก่อนถึง route (เช่น 401 จาก `authenticate` ที่ใส่ไว้ระดับ router) ได้ `<mount ลึกสุด>/*` เช่น
 * `/api/v1/orders/*` ยังบอกได้ว่าเป็นของโมดูลไหน ไม่เข้า mount ไหนเลยได้ `unmatched` — ทุกค่ามาจาก route/mount
 * ที่มีอยู่จริงในโค้ด จำนวนจึงจำกัดเสมอ
 */
const trackRoute = (req) => {
  let route = req.route;
  let baseUrl = req.baseUrl;
  let template;
  let deepestMount = '';

  Object.defineProperty(req, 'baseUrl', {
    configurable: true,
    enumerable: true,
    get: () => baseUrl,
    set: (value) => {
      baseUrl = value;
      if (typeof value === 'string' && value.length > deepestMount.length) deepestMount = value;
    },
  });
  Object.defineProperty(req, 'route', {
    configurable: true,
    enumerable: true,
    get: () => route,
    set: (value) => {
      route = value;
      if (typeof value?.path === 'string') template = `${baseUrl ?? ''}${value.path}` || '/';
    },
  });

  return () => template ?? (deepestMount ? `${deepestMount}/*` : UNMATCHED_ROUTE);
};

/**
 * middleware ตัวแรกสุดของแอป (ก่อน helmet/cors/body parser) ทุกคำขอ:
 *  - รับ `x-request-id` ของผู้เรียกถ้าตรง `^[\w-]{8,64}$` ไม่งั้นสร้างใหม่ ส่งกลับใน response header
 *    (errorHandler ใส่ใน error body ด้วย) แอปแสดงรหัสนี้ตอน error ให้ร้านแจ้งแล้วโยงหา log ได้
 *  - ให้รหัสนี้ (และ trace id จาก `traceparent` ถ้ามี) เป็นบริบทของทุกบรรทัด log ระหว่างทำคำขอ
 *  - พอ response เสร็จ เขียน `http.request.completed` (path ไม่มี query string, status, latency) และนับ metric
 *    ตาม route template
 *
 * ไม่มีอะไรจาก body, query string หรือ header ของคำขอถูกเขียนลง log เลย
 */
export const requestContext = (req, res, next) => {
  const correlationId = acceptRequestId(req.headers['x-request-id']) ?? randomUUID();
  const context = { correlationId, traceId: parseTraceparent(req.headers.traceparent) };
  const routeTemplate = trackRoute(req);
  const started = process.hrtime.bigint();

  req.requestId = correlationId;
  res.setHeader('x-request-id', correlationId);

  res.once('finish', () => {
    const elapsedMs = Number(process.hrtime.bigint() - started) / 1e6;
    const path = redactPath(requestPath(req.originalUrl ?? req.url));
    const status = res.statusCode;

    observeRequest(req.method, routeTemplate(), status, elapsedMs / 1000);
    writeLog({
      severity: severityForStatus(status),
      event: 'http.request.completed',
      message: `${req.method} ${path} ${status}`,
      // response เสร็จแล้ว บริบทของคำขออาจหลุดไปแล้ว จึงส่งค่าเองตรง ๆ
      correlationId,
      traceId: context.traceId,
      locationCode: context.locationCode,
      httpRequest: {
        requestMethod: req.method,
        requestUrl: path,
        status,
        latency: formatLatency(elapsedMs),
      },
      error: status >= 500 ? res.locals[RESPONSE_ERROR] : undefined,
    });
  });

  runWithRequestContext(context, next);
};
