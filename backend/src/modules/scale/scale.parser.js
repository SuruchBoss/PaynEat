// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/**
 * แปลงข้อความหนึ่งบรรทัดจากตาชั่งเป็นน้ำหนัก (ดู docs/tickets/22-live-scale-camera-scan.md,
 * docs/DECISIONS.md #54) — ตาชั่งดิจิทัลแทบทุกยี่ห้อส่งน้ำหนักออกพอร์ตเป็นข้อความ ASCII บรรทัดละค่า
 * แต่ละยี่ห้อต่างกันแค่รูปแบบ จึงรองรับ 3 ตระกูลที่เจอบ่อยในไทย:
 *
 *   A&D / CAS / ตาชั่งจีนส่วนใหญ่   "ST,GS,+0000.485kg"   (ST = นิ่ง, US = ยังแกว่ง, OL = เกินพิกัด)
 *   Mettler Toledo MT-SICS          "S S      0.485 kg"   (S S = นิ่ง, S D = ยังแกว่ง, S + / S - = เกิน/ขาด)
 *   ตัวเลข + หน่วย ล้วน ๆ            "0.485 kg" / "485 g"  (ไม่บอกว่านิ่งไหม — ถือว่านิ่ง)
 *
 * คืน null ถ้าอ่านไม่ออก (บรรทัดว่าง/ข้อความอื่นที่ตาชั่งส่งปน) — ผู้เรียกแค่ข้ามไป ไม่ใช่ error
 * น้ำหนักเป็นกรัมจำนวนเต็มเหมือนที่เก็บใน order_items.weight_grams
 */

const UNIT_TO_GRAMS = { kg: 1000, g: 1, lb: 453.59237, oz: 28.349523125 };

const NUMBER_WITH_UNIT = /([+-]?)\s*(\d+(?:\.\d+)?)\s*(kg|g|lb|oz)\b/i;

const toGrams = (sign, number, unit) => {
  const grams = Math.round(Number(number) * UNIT_TO_GRAMS[unit.toLowerCase()]);
  return sign === '-' ? -grams : grams;
};

const reading = ({ grams, stable, overload = false }) => ({
  grams,
  stable: stable && !overload && grams >= 0,
  overload,
});

export const parseScaleLine = (line) => {
  const text = String(line ?? '').trim();
  if (!text) return null;

  // A&D / CAS: <สถานะ>,<ชนิด>,<น้ำหนัก><หน่วย>
  const header = /^(ST|US|OL|QT)\s*,\s*(GS|NT|TR|G|N)?\s*,?/i.exec(text);
  if (header) {
    const status = header[1].toUpperCase();
    if (status === 'OL') return reading({ grams: 0, stable: false, overload: true });
    const match = NUMBER_WITH_UNIT.exec(text.slice(header[0].length));
    if (!match) return null;
    return reading({ grams: toGrams(match[1], match[2], match[3]), stable: status === 'ST' });
  }

  // MT-SICS: "S S 0.485 kg" / "SI" ตอบกลับด้วยรูปแบบเดียวกัน
  const sics = /^S\s+([SD+-I])\s*(.*)$/i.exec(text);
  if (sics) {
    const flag = sics[1].toUpperCase();
    if (flag === '+' || flag === '-') return reading({ grams: 0, stable: false, overload: true });
    if (flag === 'I') return null; // ตาชั่งไม่ว่างรับคำสั่ง — รอบหน้าค่อยอ่านใหม่
    const match = NUMBER_WITH_UNIT.exec(sics[2]);
    if (!match) return null;
    return reading({ grams: toGrams(match[1], match[2], match[3]), stable: flag === 'S' });
  }

  // ตัวเลข + หน่วย (บางรุ่นขึ้นต้นด้วยตัวอักษรบอกสถานะ เช่น "W" หรือ "=" — ข้ามไป)
  const plain = NUMBER_WITH_UNIT.exec(text);
  if (plain) return reading({ grams: toGrams(plain[1], plain[2], plain[3]), stable: true });
  return null;
};

export default parseScaleLine;
