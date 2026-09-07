import 'dotenv/config';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

const toInt = (value, fallback) => {
  const parsed = Number.parseInt(value ?? '', 10);
  return Number.isNaN(parsed) ? fallback : parsed;
};

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
    secret: process.env.JWT_SECRET ?? 'payneat-dev-secret-change-me',
    expiresIn: process.env.JWT_EXPIRES_IN ?? '12h',
  },
  corsOrigin: (process.env.CORS_ORIGIN ?? '*').split(',').map((item) => item.trim()),
  // ค่าเริ่มต้นของร้าน ใช้ตอนคำนวณบิล (ปรับได้ที่ตาราง settings)
  store: {
    name: process.env.STORE_NAME ?? 'PaynEat Restaurant',
    currency: process.env.CURRENCY ?? 'THB',
    vatRate: Number(process.env.VAT_RATE ?? 0.07),
    serviceChargeRate: Number(process.env.SERVICE_CHARGE_RATE ?? 0.1),
    vatIncluded: (process.env.VAT_INCLUDED ?? 'false') === 'true',
  },
};

export default env;
