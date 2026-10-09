// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { storeDate, storeDayRange, storeNow } from '../../core/storeTime.js';
import { settingsService } from './settings.service.js';

/**
 * นาฬิกาของร้าน (T03 #94, docs/DECISIONS.md #101) — ตัวช่วยกลางที่ตอบ "วันนี้ของร้านคือวันไหน", "ช่วง UTC ของวัน X ของร้าน"
 * และ "เวลาท้องถิ่นของร้านตอนนี้" ตามเขตเวลาที่ตั้งไว้ในหน้าตั้งค่า ไม่ขึ้นกับ `TZ` ของเครื่องเซิร์ฟเวอร์
 * ยังไม่มีรายงานใดเรียกใช้ รายงาน โปรโมชัน และเลขเอกสารย้ายมาใช้ตัวนี้ใน T16/T17
 */
export const storeClock = {
  timeZone: () => settingsService.get().timeZone,
  today: (now = new Date()) => storeDate(now, storeClock.timeZone()),
  dayRange: (date) => storeDayRange(date, storeClock.timeZone()),
  now: (now = new Date()) => storeNow(storeClock.timeZone(), now),
};

export default storeClock;
