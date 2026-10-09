// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/**
 * วันและเวลาตามเขตเวลาของร้าน (T03 #94, docs/DECISIONS.md #101) — ไม่ขึ้นกับ `TZ` ของเครื่องเซิร์ฟเวอร์
 *
 * ทุกฟังก์ชันรับเขตเวลา IANA (เช่น `Asia/Bangkok`) เป็นพารามิเตอร์ และคิดผ่าน `Intl.DateTimeFormat` เท่านั้น
 * ไม่ใช้ `Date#getHours()` / `getDate()` ที่อ่านเขตเวลาของเครื่อง ผลจึงเหมือนกันไม่ว่าเครื่องตั้ง `TZ=UTC` หรือ `TZ=Asia/Bangkok`
 * เวลาที่เก็บในฐานข้อมูลยังเป็น UTC เหมือนเดิม ตัวช่วยนี้ตอบแค่ว่าเวลา UTC นั้นตรงกับวันไหนของร้าน และวันหนึ่งของร้านคือช่วง UTC ไหน
 */

export const DEFAULT_TIME_ZONE = 'Asia/Bangkok';

const DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/;
// ชื่อ IANA ขึ้นต้นด้วยตัวอักษรและมีภูมิภาค (`Area/Location`) ยกเว้น `UTC` — กันค่าแบบ offset (`+07:00`)
// และตัวย่อเก่าอย่าง `EST` ที่ Intl รับได้แต่ไม่ใช่ชื่อเขตเวลาที่ร้านควรตั้ง
const IANA_NAME = /^(?:UTC|[A-Za-z][A-Za-z0-9_+-]*(?:\/[A-Za-z0-9_+-]+)+)$/;

const formatters = new Map();
const formatterFor = (timeZone) => {
  let formatter = formatters.get(timeZone);
  if (!formatter) {
    formatter = new Intl.DateTimeFormat('en-US', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hourCycle: 'h23',
    });
    formatters.set(timeZone, formatter);
  }
  return formatter;
};

/**
 * ชื่อเขตเวลาแบบที่เก็บได้ (ตัวพิมพ์ตาม IANA เช่น `asia/bangkok` → `Asia/Bangkok`) หรือ `null` ถ้าไม่ใช่เขตเวลา IANA
 */
export const normalizeTimeZone = (value) => {
  if (typeof value !== 'string') return null;
  const name = value.trim();
  if (!IANA_NAME.test(name)) return null;
  try {
    return new Intl.DateTimeFormat('en-US', { timeZone: name }).resolvedOptions().timeZone;
  } catch {
    return null;
  }
};

export const isValidTimeZone = (value) => normalizeTimeZone(value) !== null;

const toDate = (instant) => (instant instanceof Date ? instant : new Date(instant));

/** ปี เดือน วัน ชั่วโมง นาที วินาที ของเวลา `instant` ตามนาฬิกาของร้าน */
const wallClock = (instant, timeZone) => {
  const parts = Object.fromEntries(
    formatterFor(timeZone)
      .formatToParts(toDate(instant))
      .filter((part) => part.type !== 'literal')
      .map((part) => [part.type, Number(part.value)]),
  );
  return parts;
};

const pad = (value, width = 2) => String(value).padStart(width, '0');

/** ระยะห่างของนาฬิการ้านจาก UTC (มิลลิวินาที) ณ เวลา `instantMs` — บวกคือเร็วกว่า UTC */
const offsetAt = (instantMs, timeZone) => {
  const c = wallClock(instantMs, timeZone);
  const asUtc = Date.UTC(c.year, c.month - 1, c.day, c.hour, c.minute, c.second);
  return asUtc - Math.floor(instantMs / 1000) * 1000;
};

/** วันที่ของร้าน (`YYYY-MM-DD`) ของเวลา `instant` */
export const storeDate = (instant, timeZone = DEFAULT_TIME_ZONE) => {
  const c = wallClock(instant, timeZone);
  return `${pad(c.year, 4)}-${pad(c.month)}-${pad(c.day)}`;
};

/** วันที่และเวลาท้องถิ่นของร้านตอนนี้ (หรือ ณ `now`) */
export const storeNow = (timeZone = DEFAULT_TIME_ZONE, now = new Date()) => {
  const c = wallClock(now, timeZone);
  return {
    timeZone,
    date: `${pad(c.year, 4)}-${pad(c.month)}-${pad(c.day)}`,
    time: `${pad(c.hour)}:${pad(c.minute)}:${pad(c.second)}`,
  };
};

/** เวลา UTC ที่นาฬิการ้านขึ้นวันที่ `y-m-d` 00:00 (ถ้าเที่ยงคืนวันนั้นไม่มีเพราะเปลี่ยนเวลาออมแสง ได้เวลาแรกของวันนั้น) */
const startOfDayMs = (year, month, day, timeZone) => {
  const guess = Date.UTC(year, month - 1, day);
  const first = guess - offsetAt(guess, timeZone);
  const start = guess - offsetAt(first, timeZone);
  const wanted = `${pad(year, 4)}-${pad(month)}-${pad(day)}`;
  if (storeDate(start, timeZone) >= wanted) return start;
  // เที่ยงคืนวันนั้นไม่มีจริง (นาฬิกาเลื่อนข้ามช่วงเที่ยงคืน) — วันเริ่มตอนเลื่อนเวลา หาเวลาแรกที่เป็นวันนั้นทีละวินาที
  // ในช่วงไม่เกิน 3 ชั่วโมงถัดไป (การเลื่อนเวลาทุกแบบสั้นกว่านั้น)
  let low = start;
  let high = start + 3 * 3600000;
  while (high - low > 1000) {
    const mid = low + Math.floor((high - low) / 2000) * 1000;
    if (storeDate(mid, timeZone) >= wanted) high = mid;
    else low = mid;
  }
  return high;
};

/**
 * ช่วง UTC ของวัน `date` (`YYYY-MM-DD`) ของร้าน แบบ [start, end) — end คือเวลาเริ่มของวันถัดไป
 * วันที่เปลี่ยนเวลาออมแสงจึงยาว 23 หรือ 25 ชั่วโมงได้ตามจริง
 */
export const storeDayRange = (date, timeZone = DEFAULT_TIME_ZONE) => {
  const match = DATE_ONLY.exec(String(date));
  if (!match) throw new TypeError(`วันที่ต้องเป็น YYYY-MM-DD: ${date}`);
  const [year, month, day] = match.slice(1).map(Number);
  const next = new Date(Date.UTC(year, month - 1, day + 1));
  return {
    start: new Date(startOfDayMs(year, month, day, timeZone)).toISOString(),
    end: new Date(
      startOfDayMs(next.getUTCFullYear(), next.getUTCMonth() + 1, next.getUTCDate(), timeZone),
    ).toISOString(),
  };
};
