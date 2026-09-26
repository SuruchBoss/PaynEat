// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/**
 * ตัวช่วยสินค้าขายตามน้ำหนัก (ดู docs/tickets/18-sell-by-weight.md) — น้ำหนักเก็บเป็น "กรัม" (integer)
 * เสมอเหมือนเงินที่เก็บเป็นสตางค์ ไม่เก็บกิโลกรัมเป็นทศนิยมในฐานข้อมูล
 */

/**
 * จำนวนหน่วยที่ขายไปของบรรทัดนี้สำหรับตัดสต๊อก — บรรทัดชั่งน้ำหนักคือกิโลกรัม (485 กรัม = 0.485)
 * ส่วนบรรทัดขายเป็นชิ้นคือ quantity ตรง ๆ วัตถุดิบที่ผูกกับเมนูขายตามน้ำหนักจึงตั้ง "ปริมาณต่อ 1 กก."
 */
export const effectiveQuantity = (item) => {
  const grams = Number(item.weight_grams ?? item.weightGrams ?? 0);
  return grams > 0 ? grams / 1000 : Number(item.quantity) || 0;
};

/** แสดงน้ำหนักแบบที่ใบเสร็จ/log ใช้ เช่น 485 → "0.485 กก." */
export const formatKg = (grams) => `${(Number(grams) / 1000).toFixed(3)} กก.`;

/** "ข้าวผัด x2" หรือ "หมูสามชั้น 0.485 กก." — ใช้ในข้อความ audit log ของรายการอาหาร */
export const describeLine = (name, { quantity, weightGrams }) =>
  weightGrams ? `${name} ${formatKg(weightGrams)}` : `${name} x${quantity}`;
