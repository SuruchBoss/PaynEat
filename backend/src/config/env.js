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
  // ผู้ช่วย AI ถามตอบข้อมูลร้าน (ดู docs/tickets/15-ai-ask-your-data.md) — ปิดเองอัตโนมัติถ้าไม่ตั้ง
  // ANTHROPIC_API_KEY (คืน 503 ที่ endpoint แทนที่จะ throw ตอน start เหมือน JWT_SECRET เพราะฟีเจอร์นี้
  // เป็นของเสริมที่ปิดได้โดยไม่กระทบ POS หลัก ต่างจาก auth ที่ทั้งระบบพังถ้าไม่มี)
  aiAssistant: {
    apiKey: process.env.ANTHROPIC_API_KEY,
    model: process.env.AI_ASSISTANT_MODEL ?? 'claude-opus-5',
    dailyLimitPerUser: toInt(process.env.AI_ASSISTANT_DAILY_LIMIT, 20),
  },
  // ส่งเอกสารลูกหนี้ (ใบวางบิล ฯลฯ) เป็น PDF ทางอีเมล (ดู docs/tickets/23-document-pdf-email.md) — ปิด
  // เองถ้าไม่ตั้ง SMTP_HOST (endpoint ส่งอีเมลคืน 503 ดาวน์โหลด PDF ยังใช้ได้) หลักเดียวกับผู้ช่วย AI
  // MAIL_TRANSPORT=json ใช้ในเทสต์/E2E: nodemailer สร้างอีเมลครบทุกส่วนแต่ไม่ส่งออกไปจริง
  mail: {
    transport: process.env.MAIL_TRANSPORT === 'json' ? 'json' : 'smtp',
    host: process.env.SMTP_HOST,
    port: toInt(process.env.SMTP_PORT, 587),
    secure: (process.env.SMTP_SECURE ?? String(process.env.SMTP_PORT === '465')) === 'true',
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
    from: process.env.MAIL_FROM ?? process.env.SMTP_USER,
  },
  // ตาชั่งต่อสาย (ดู docs/tickets/22-live-scale-camera-scan.md) — เซิร์ฟเวอร์ร้านอ่านน้ำหนักแล้วกระจายให้
  // แอปทุกเครื่องผ่าน socket.io ค่าเริ่มต้นปิด (off) ร้านที่ไม่มีตาชั่งไม่ต้องตั้งอะไร
  //   tcp       — ตาชั่งที่มีพอร์ต LAN หรือต่อผ่านกล่องแปลง Serial→Ethernet
  //   serial    — ต่อ USB/RS-232 เข้าเครื่องที่รันเซิร์ฟเวอร์ตรง (ต้องมีแพ็กเกจ serialport)
  //   simulator — ตาชั่งจำลอง ใช้เดโม/ทดสอบหน้าร้านโดยไม่มีเครื่องจริง
  scale: {
    driver: ['tcp', 'serial', 'simulator'].includes(process.env.SCALE_DRIVER)
      ? process.env.SCALE_DRIVER
      : 'off',
    host: process.env.SCALE_TCP_HOST ?? '127.0.0.1',
    port: toInt(process.env.SCALE_TCP_PORT, 4001),
    serialPath: process.env.SCALE_SERIAL_PATH,
    baudRate: toInt(process.env.SCALE_BAUD_RATE, 9600),
    // ตาชั่งแบบถาม-ตอบ (ไม่ส่งน้ำหนักเองต่อเนื่อง) ต้องส่งคำสั่งขอน้ำหนักเป็นระยะ เช่น MT-SICS ใช้ "SI"
    pollCommand: process.env.SCALE_POLL_COMMAND,
    pollMs: toInt(process.env.SCALE_POLL_MS, 500),
  },
};

export default env;
