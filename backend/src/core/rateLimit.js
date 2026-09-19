import { ApiError } from './ApiError.js';

/**
 * ตัวจำกัดจำนวน request แบบ fixed-window เก็บ state ในหน่วยความจำล้วน (เขียนเองแทนพึ่ง
 * express-rate-limit เพราะโจทย์เล็ก — เทียบหลักการเดียวกับที่เขียน `Result<T>`/PromptPay TLV เอง
 * ดู docs/DECISIONS.md #3) ใช้ได้เฉพาะเซิร์ฟเวอร์ instance เดียว (ตามที่โปรเจกต์นี้ deploy จริง) —
 * ถ้าต้องขยายเป็นหลาย instance ต้องย้าย state ไป Redis หรือเทียบเท่า
 *
 * ตั้งใจไม่ทำ cleanup คีย์เก่าทิ้ง เพราะผู้เรียกทุกจุดตอนนี้ (ดู public-order.routes.js) คีย์ด้วย
 * qrToken ซึ่งมีจำนวนจำกัดเท่าจำนวนโต๊ะในระบบ (ไม่ใช่คีย์ที่โตไม่มีที่สิ้นสุดแบบ IP) จึงไม่รั่วหน่วยความจำ
 */
const buckets = new Map();

export const rateLimit =
  ({ windowMs, max, keyFn }) =>
  (req, _res, next) => {
    const key = keyFn(req);
    const now = Date.now();
    const bucket = buckets.get(key);

    if (!bucket || now - bucket.start > windowMs) {
      buckets.set(key, { start: now, count: 1 });
      return next();
    }

    bucket.count += 1;
    if (bucket.count > max) {
      return next(ApiError.tooManyRequests());
    }
    return next();
  };

export default rateLimit;
