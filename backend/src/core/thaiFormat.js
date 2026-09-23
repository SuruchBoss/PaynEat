/**
 * รูปแบบตัวเลข/วันที่แบบเอกสารธุรกิจไทย — ใช้กับ PDF และอีเมลที่ส่งให้ลูกค้า (ดู docs/DECISIONS.md #57)
 * วันที่เป็น พ.ศ. เขตเวลากรุงเทพฯ เสมอ ไม่ขึ้นกับ timezone ของเครื่องเซิร์ฟเวอร์ (container มักเป็น UTC)
 */

const DATE_ONLY = /^\d{4}-\d{2}-\d{2}$/;

const dateFormat = new Intl.DateTimeFormat('th-TH', {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
  timeZone: 'Asia/Bangkok',
});
const dateOnlyFormat = new Intl.DateTimeFormat('th-TH', {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
  timeZone: 'UTC',
});
const timeFormat = new Intl.DateTimeFormat('th-TH', {
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
  timeZone: 'Asia/Bangkok',
});

/**
 * SQLite datetime('now') ให้ "YYYY-MM-DD HH:MM:SS" ที่เป็น UTC แต่ไม่มี Z ต่อท้าย — ต้องบอกเองว่าเป็น UTC
 * ส่วนวันที่ล้วน (วันครบกำหนด) เป็นวันตามปฏิทินอยู่แล้ว ห้ามแปลง timezone ไม่งั้นวันเลื่อน
 */
const parse = (value) => {
  if (value instanceof Date) return value;
  const text = String(value);
  if (DATE_ONLY.test(text)) return new Date(`${text}T00:00:00Z`);
  return new Date(/[zZ]|[+-]\d\d:?\d\d$/.test(text) ? text : `${text.replace(' ', 'T')}Z`);
};

/** "23 ก.ย. 2569" — '-' ถ้าไม่มีค่า */
export const thaiDate = (value) => {
  if (!value) return '-';
  const text = String(value);
  return (DATE_ONLY.test(text) ? dateOnlyFormat : dateFormat).format(parse(value));
};

/** "23 ก.ย. 2569 14:05" */
export const thaiDateTime = (value) => {
  if (!value) return '-';
  const date = parse(value);
  return `${dateFormat.format(date)} ${timeFormat.format(date)}`;
};

/** 1234.5 → "1,234.50" */
export const money = (baht) =>
  Number(baht ?? 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const DIGITS = ['ศูนย์', 'หนึ่ง', 'สอง', 'สาม', 'สี่', 'ห้า', 'หก', 'เจ็ด', 'แปด', 'เก้า'];
const PLACES = ['', 'สิบ', 'ร้อย', 'พัน', 'หมื่น', 'แสน'];

/** อ่านเลข 1–999,999 (หลักล้านขึ้นไปวนซ้ำด้วย readNumber) */
const readChunk = (value) => {
  const digits = String(value).split('').reverse().map(Number);
  let text = '';
  digits.forEach((digit, place) => {
    if (digit === 0) return;
    let word = DIGITS[digit];
    if (place === 0 && digit === 1 && value > 10) word = 'เอ็ด';
    else if (place === 1 && digit === 2) word = 'ยี่';
    else if (place === 1 && digit === 1) word = '';
    text = `${word}${PLACES[place]}${text}`;
  });
  return text;
};

const readNumber = (value) => {
  if (value >= 1_000_000) {
    const rest = value % 1_000_000;
    return `${readNumber(Math.floor(value / 1_000_000))}ล้าน${rest ? readChunk(rest) : ''}`;
  }
  return readChunk(value);
};

/**
 * จำนวนเงินเป็นตัวอักษรแบบ BAHTTEXT ที่เอกสารการเงินไทยต้องมีกำกับยอดรวม
 * 1234.5 → "หนึ่งพันสองร้อยสามสิบสี่บาทห้าสิบสตางค์", 21 → "ยี่สิบเอ็ดบาทถ้วน"
 */
export const bahtText = (baht) => {
  const satang = Math.round(Math.abs(Number(baht ?? 0)) * 100);
  const whole = Math.floor(satang / 100);
  const fraction = satang % 100;
  if (whole === 0 && fraction === 0) return 'ศูนย์บาทถ้วน';
  const prefix = Number(baht) < 0 ? 'ลบ' : '';
  const bahtPart = whole > 0 ? `${readNumber(whole)}บาท` : '';
  const satangPart = fraction > 0 ? `${readNumber(fraction)}สตางค์` : 'ถ้วน';
  return `${prefix}${bahtPart}${satangPart}`;
};
