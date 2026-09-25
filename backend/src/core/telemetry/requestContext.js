import { AsyncLocalStorage } from 'node:async_hooks';
import { randomUUID } from 'node:crypto';
import { isLocationCode } from './logRecord.js';

/**
 * บริบทของคำขอที่กำลังทำอยู่ (correlation id, trace id, สาขา) — ทุกบรรทัด log ที่เขียนระหว่างทำคำขอหนึ่ง
 * ได้ค่าเหล่านี้เองโดยไม่ต้องส่งต่อเป็นพารามิเตอร์ผ่านทุกชั้น (ดู middlewares/requestContext.js)
 */
const storage = new AsyncLocalStorage();

/**
 * นอกคำขอ (ตอนเปิดเซิร์ฟเวอร์, migrate, ตาชั่ง) สัญญายังบังคับให้มี `correlation_id` ทุกบรรทัด จึงใช้รหัสเดียว
 * ต่อหนึ่ง process — ค้นแล้วได้ทุกบรรทัดของการรันครั้งนั้น
 */
export const PROCESS_CORRELATION_ID = `process-${randomUUID()}`;

export const runWithRequestContext = (context, fn) => storage.run(context, fn);

export const currentRequestContext = () => storage.getStore();

/**
 * บอกว่าคำขอนี้ทำงานกับสาขาไหน — เรียกจาก middlewares/auth.js หลังตรวจสิทธิ์สาขาแล้วเท่านั้น รหัสสาขาที่
 * ไม่ตรงรูปแบบรหัสสถานที่กลางถูกข้าม (ยังไม่ใช่รหัสของระบบนิเวศ ใส่ไปก็ query ข้ามระบบไม่ได้)
 */
export const setLocationCode = (code) => {
  const context = storage.getStore();
  if (context && isLocationCode(code)) context.locationCode = code;
};
