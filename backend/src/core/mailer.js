import nodemailer from 'nodemailer';
import { env } from '../config/env.js';
import { ApiError } from './ApiError.js';

/**
 * ส่งอีเมลผ่าน SMTP ของร้านเอง (ดู docs/DECISIONS.md #57) — ไม่ผูกกับผู้ให้บริการเจ้าไหน ร้านใช้ Gmail/
 * Microsoft 365/SMTP ของโฮสติ้งได้หมด ไม่ตั้งค่า = ปิดฟีเจอร์ (503) ไม่กระทบส่วนอื่นของ POS
 */

let transport = null;
let testTransport = null;

const createTransport = () => {
  if (env.mail.transport === 'json') return nodemailer.createTransport({ jsonTransport: true });
  return nodemailer.createTransport({
    host: env.mail.host,
    port: env.mail.port,
    secure: env.mail.secure,
    auth: env.mail.user ? { user: env.mail.user, pass: env.mail.pass } : undefined,
  });
};

export const mailer = {
  isConfigured() {
    return Boolean(testTransport || env.mail.transport === 'json' || env.mail.host);
  },

  assertConfigured() {
    if (!this.isConfigured()) {
      throw new ApiError(
        503,
        'ยังไม่ได้ตั้งค่าเซิร์ฟเวอร์อีเมล (SMTP_HOST) — ดาวน์โหลด PDF แล้วส่งให้ลูกค้าเองได้',
        { code: 'MAIL_NOT_CONFIGURED' },
      );
    }
  },

  /** ส่งอีเมล คืน messageId — โยน ApiError 503 (ไม่ได้ตั้งค่า) หรือ 502 (SMTP ปฏิเสธ/ต่อไม่ติด) */
  async send({ to, subject, text, attachments, replyTo }) {
    this.assertConfigured();
    const sender = testTransport ?? (transport ??= createTransport());
    try {
      const info = await sender.sendMail({
        from: env.mail.from || 'PaynEat <no-reply@payneat.local>',
        to,
        replyTo,
        subject,
        text,
        attachments,
      });
      return info.messageId ?? null;
    } catch (error) {
      throw new ApiError(502, `ส่งอีเมลไม่สำเร็จ: ${error.message}`, { code: 'MAIL_SEND_FAILED' });
    }
  },
};

/** เทสต์ใส่ transport ปลอม (มีเมธอด sendMail) เพื่อตรวจอีเมลที่ถูกส่ง — ส่ง null เพื่อเลิกใช้ */
export const setMailTransportForTests = (fake) => {
  testTransport = fake;
};

export default mailer;
