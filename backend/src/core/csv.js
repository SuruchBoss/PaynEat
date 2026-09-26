// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/**
 * แปลง array ของ object เป็น CSV string (RFC 4180 พื้นฐาน) — pure function เก็บไว้ที่ core
 * เพราะเป็นตัวช่วยทั่วไป ไม่ผูกกับ module ไหนโดยเฉพาะ (ดู docs/tickets/14-financial-audit-trail.md)
 */
const escapeCsvField = (value) => {
  const str = value === null || value === undefined ? '' : String(value);
  if (/[",\n\r]/.test(str)) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
};

/** columns: [{ label, value(row) }] — เรียงตามลำดับที่ต้องการให้ขึ้นในไฟล์ */
export const toCsv = (rows, columns) => {
  const header = columns.map((col) => escapeCsvField(col.label)).join(',');
  const lines = rows.map((row) => columns.map((col) => escapeCsvField(col.value(row))).join(','));
  // ขึ้นต้นด้วย UTF-8 BOM กัน Excel เปิดแล้วอักษรไทยเพี้ยน (Excel เดาเป็น ANSI ถ้าไม่มี BOM)
  const bom = String.fromCharCode(0xfeff);
  return bom + [header, ...lines].join('\r\n');
};

export default toCsv;
