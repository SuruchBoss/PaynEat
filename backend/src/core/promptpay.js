/**
 * สร้าง payload สำหรับ QR พร้อมเพย์ (PromptPay) ตามมาตรฐาน EMV QRCPS Merchant Presented Mode
 * ที่ธนาคารแห่งประเทศไทยประกาศใช้ — เขียนเป็น pure function ล้วน (เหมือน money.js) แทนที่จะ
 * เพิ่ม dependency ภายนอก เพราะอัลกอริทึมสั้นและเสถียร (ไม่เปลี่ยนบ่อย เป็นมาตรฐานสาธารณะ)
 *
 * อ้างอิงโครงสร้าง TLV และการคำนวณ CRC จาก dtinth/promptpay-qr (MIT) ซึ่งเป็น implementation
 * อ้างอิงที่ใช้กันแพร่หลายที่สุดสำหรับ QR พร้อมเพย์ฝั่ง JavaScript
 */

const ID_PAYLOAD_FORMAT = '00';
const ID_POI_METHOD = '01';
const ID_MERCHANT_INFORMATION_BOT = '29';
const ID_COUNTRY_CODE = '58';
const ID_TRANSACTION_CURRENCY = '53';
const ID_TRANSACTION_AMOUNT = '54';
const ID_CRC = '63';

const GUID_PROMPTPAY = 'A000000677010111';
const TAG_MERCHANT_GUID = '00';
const TAG_TARGET_PHONE = '01';
const TAG_TARGET_TAX_ID = '02';
const TAG_TARGET_EWALLET = '03';

/** id (2 ตัว) + ความยาวของ value (2 หลัก, เติม 0 ข้างหน้า) + value ต่อกันตามสเปก TLV ของ EMV QR */
const tlv = (id, value) => `${id}${String(value.length).padStart(2, '0')}${value}`;

const sanitizeDigits = (value) => String(value ?? '').replace(/[^0-9]/g, '');

/**
 * แปลงเลขพร้อมเพย์ให้เป็นรูปแบบที่ QR ต้องการ — เบอร์โทร 10 หลัก (ขึ้นต้น 0) ต้องแปลงเป็น
 * รหัสประเทศ 66 แล้วเติม 0 ข้างหน้าให้ครบ 13 หลัก ส่วนเลขบัตรประชาชน/เลขผู้เสียภาษี (13 หลัก)
 * หรือ e-Wallet ID (15 หลัก) ใช้ค่าตามที่กรอกได้เลยไม่ต้องแปลง
 */
const formatTarget = (digits) => {
  if (digits.length >= 13) return digits;
  return `0000000000000${digits.replace(/^0/, '66')}`.slice(-13);
};

const targetTagFor = (digits) => {
  if (digits.length >= 15) return TAG_TARGET_EWALLET;
  if (digits.length >= 13) return TAG_TARGET_TAX_ID;
  return TAG_TARGET_PHONE;
};

/**
 * CRC-16/CCITT-FALSE (polynomial 0x1021, initial value 0xFFFF, ไม่ reflect, xorout 0)
 * ตามที่สเปก EMV QR กำหนดไว้สำหรับฟิลด์ CRC (tag 63) — ทดสอบแล้วตรงกับ test vector มาตรฐาน
 * ของ CRC-16/CCITT-FALSE คือ "123456789" → 0x29B1
 */
export const crc16ccitt = (str) => {
  let crc = 0xffff;
  for (let i = 0; i < str.length; i += 1) {
    crc ^= str.charCodeAt(i) << 8;
    for (let bit = 0; bit < 8; bit += 1) {
      crc = crc & 0x8000 ? ((crc << 1) ^ 0x1021) & 0xffff : (crc << 1) & 0xffff;
    }
  }
  return crc;
};

/**
 * สร้าง payload ข้อความสำหรับ QR พร้อมเพย์ — เอาไปเรนเดอร์เป็นภาพ QR ฝั่ง client ได้เลย
 * (ระบบนี้ไม่มี payment gateway/callback ตรวจสอบการจ่ายอัตโนมัติ — ลูกค้าสแกนแล้วแคชเชียร์ต้อง
 * เช็คสลิป/แอปธนาคารเองว่าจ่ายจริง เหมือนช่องทาง card/transfer ดู docs/tickets/16-promptpay-qr.md)
 */
export const buildPromptPayPayload = ({ promptPayId, amount }) => {
  const digits = sanitizeDigits(promptPayId);
  if (!digits) {
    throw new Error('promptPayId ต้องเป็นเบอร์โทร/เลขบัตรประชาชน/เลขผู้เสียภาษีของร้าน');
  }
  const targetTag = targetTagFor(digits);
  const hasAmount = amount !== undefined && amount !== null;

  const parts = [
    tlv(ID_PAYLOAD_FORMAT, '01'),
    tlv(ID_POI_METHOD, hasAmount ? '12' : '11'),
    tlv(
      ID_MERCHANT_INFORMATION_BOT,
      tlv(TAG_MERCHANT_GUID, GUID_PROMPTPAY) + tlv(targetTag, formatTarget(digits)),
    ),
    tlv(ID_COUNTRY_CODE, 'TH'),
    tlv(ID_TRANSACTION_CURRENCY, '764'),
  ];
  if (hasAmount) parts.push(tlv(ID_TRANSACTION_AMOUNT, Number(amount).toFixed(2)));

  const payloadBeforeCrc = parts.join('') + ID_CRC + '04';
  const crc = crc16ccitt(payloadBeforeCrc).toString(16).toUpperCase().padStart(4, '0');
  return payloadBeforeCrc + crc;
};

export default buildPromptPayPayload;
