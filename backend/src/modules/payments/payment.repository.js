// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { getDb } from '../../db/index.js';

export const paymentRepository = {
  /** ย้ายการชำระทั้งหมดของออเดอร์หนึ่งไปอีกออเดอร์ — ใช้ตอนรวมบิล (T09 #96, docs/DECISIONS.md #98) กะของแต่ละ payment ไม่เปลี่ยน */
  reassignToOrder(fromOrderId, toOrderId) {
    return getDb()
      .prepare('UPDATE payments SET order_id = ? WHERE order_id = ?')
      .run(toOrderId, fromOrderId).changes;
  },

  /** การชำระที่ผูกกับลูกค้าของบิล (ขายเชื่อลงบัญชีลูกค้า หรือใช้แต้มสะสม) ย้ายไปบิลของลูกค้าอื่นไม่ได้ */
  countCustomerBound(orderId) {
    return getDb()
      .prepare(
        "SELECT COUNT(*) AS c FROM payments WHERE order_id = ? AND (method = 'credit' OR points_redeemed > 0)",
      )
      .get(orderId).c;
  },

  findByOrder(orderId) {
    return getDb()
      .prepare(
        `
        SELECT p.*, u.name AS cashier_name
          FROM payments p
          LEFT JOIN users u ON u.id = p.cashier_id
         WHERE p.order_id = ?
         ORDER BY p.id
      `,
      )
      .all(orderId);
  },

  findById(id) {
    return getDb()
      .prepare(
        `
        SELECT p.*, u.name AS cashier_name
          FROM payments p
          LEFT JOIN users u ON u.id = p.cashier_id
         WHERE p.id = ?
      `,
      )
      .get(id);
  },

  /**
   * เงินที่ร้านถือไว้สำหรับออเดอร์นี้ = ยอดชำระ − ยอดคืนเงิน (T06 #82, docs/DECISIONS.md #77 D1, #87) — นิยามเดียวที่ใช้
   * คำนวณยอดคงเหลือและสถานะจ่ายครบทุกจุด คืนเงินบนบิลที่ยังเปิดจึงทำให้ยอดคงเหลือเพิ่มขึ้นตามจริง
   */
  netPaid(orderId) {
    return getDb()
      .prepare(
        `SELECT (SELECT IFNULL(SUM(amount), 0) FROM payments WHERE order_id = ?)
              - (SELECT IFNULL(SUM(amount), 0) FROM refunds WHERE order_id = ?) AS total`,
      )
      .get(orderId, orderId).total;
  },

  create({
    orderId,
    shiftId,
    method,
    amount,
    received,
    changeAmount,
    reference,
    cashierId,
    pointsRedeemed,
    pointsRedeemedValue,
    dueDate,
  }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO payments (
          order_id, shift_id, method, amount, received, change_amount, reference, cashier_id,
          points_redeemed, points_redeemed_value, due_date
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      )
      .run(
        orderId,
        shiftId,
        method,
        amount,
        received,
        changeAmount,
        reference ?? null,
        cashierId ?? null,
        pointsRedeemed ?? 0,
        pointsRedeemedValue ?? 0,
        dueDate ?? null,
      );
    return this.findById(info.lastInsertRowid);
  },
};

export default paymentRepository;
