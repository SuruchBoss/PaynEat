import 'dotenv/config';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

const toInt = (value, fallback) => {
  const parsed = Number.parseInt(value ?? '', 10);
  return Number.isNaN(parsed) ? fallback : parsed;
};

// ห้ามมี fallback secret ที่ใช้งานได้จริงในโค้ด — ถ้าใครก็ตามที่เห็นซอร์สนี้รู้ค่า default
// ก็ปลอม JWT สิทธิ์ admin ได้ทันทีถ้าเซิร์ฟเวอร์ไหนลืมตั้งค่า env นี้ (ดู SECURITY.md)
// จึงบังคับให้ตั้งค่าเองเสมอ ไม่ตั้งค่าก็ไม่ต้องให้เซิร์ฟเวอร์ start (fail-closed)
if (!process.env.JWT_SECRET) {
  throw new Error(
    'ต้องตั้งค่า JWT_SECRET ใน environment ก่อนรันเซิร์ฟเวอร์ (ดู .env.example) — ' +
      'ไม่มีค่าเริ่มต้นให้เพื่อความปลอดภัย',
  );
}

export const env = {
  rootDir,
  nodeEnv: process.env.NODE_ENV ?? 'development',
  isTest: process.env.NODE_ENV === 'test',
  port: toInt(process.env.PORT, 3000),
  host: process.env.HOST ?? '0.0.0.0',
  databaseFile: process.env.DATABASE_FILE
    ? path.resolve(rootDir, process.env.DATABASE_FILE)
    : path.resolve(rootDir, 'data/payneat.sqlite'),
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN ?? '12h',
  },
  // ค่าเริ่มต้น (ไม่ตั้ง CORS_ORIGIN) คือ '*' แบบ string ตรงๆ ให้ cors ใช้ wildcard path จริง —
  // เดิม .split(',') ทำให้ได้ array ['*'] ซึ่ง cors package เทียบแบบ exact-string จึงไม่ match
  // origin จริงของเบราว์เซอร์เลยสักตัว (ปิดกั้น cross-origin ทั้งหมดโดยไม่ตั้งใจ ดู security review #6)
  corsOrigin: process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',').map((item) => item.trim())
    : '*',
  // ค่าเริ่มต้นของร้าน ใช้ตอนคำนวณบิล (ปรับได้ที่ตาราง settings)
  store: {
    name: process.env.STORE_NAME ?? 'PaynEat Restaurant',
    currency: process.env.CURRENCY ?? 'THB',
    vatRate: Number(process.env.VAT_RATE ?? 0.07),
    serviceChargeRate: Number(process.env.SERVICE_CHARGE_RATE ?? 0.1),
    vatIncluded: (process.env.VAT_INCLUDED ?? 'false') === 'true',
    // แต้มสะสม (ดู docs/tickets/09-customer-loyalty.md) — ค่าเริ่มต้น: ซื้อครบ 25 บาทได้ 1 แต้ม
    // ใช้แต้มแลกได้ 1 แต้ม = 1 บาท (ปรับได้ที่หน้าตั้งค่า)
    pointsEarnRateBaht: Number(process.env.POINTS_EARN_RATE_BAHT ?? 25),
    pointsRedeemValueBaht: Number(process.env.POINTS_REDEEM_VALUE_BAHT ?? 1),
  },
};

export default env;
