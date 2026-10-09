// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { getDb } from '../../db/index.js';

export const refundRepository = {
  /** ย้ายการคืนเงินทั้งหมดของออเดอร์หนึ่งไปอีกออเดอร์ คู่กับ `paymentRepository.reassignToOrder` (T09 #96) */
  reassignToOrder(fromOrderId, toOrderId) {
    return getDb()
      .prepare('UPDATE refunds SET order_id = ? WHERE order_id = ?')
      .run(toOrderId, fromOrderId).changes;
  },

  findByOrder(orderId) {
    return getDb()
      .prepare(
        `
        SELECT r.*, u.name AS refunded_by_name, cn.id AS credit_note_id, cn.note_no AS credit_note_no
          FROM refunds r
          LEFT JOIN users u ON u.id = r.refunded_by
          LEFT JOIN credit_notes cn ON cn.refund_id = r.id
         WHERE r.order_id = ?
         ORDER BY r.id
      `,
      )
      .all(orderId);
  },

  totalByPayment(paymentId) {
    return getDb()
      .prepare('SELECT IFNULL(SUM(amount), 0) AS total FROM refunds WHERE payment_id = ?')
      .get(paymentId).total;
  },

  /** ยอดที่คืนไปแล้วของ payment แยกเป็นยอดตามบิล แต้มที่คืน และมูลค่าแต้มที่คืน (T11 #101) */
  returnedByPayment(paymentId) {
    return getDb()
      .prepare(
        `SELECT IFNULL(SUM(amount), 0) AS amount,
                IFNULL(SUM(points_returned), 0) AS points,
                IFNULL(SUM(points_value), 0) AS points_value
           FROM refunds WHERE payment_id = ?`,
      )
      .get(paymentId);
  },

  totalByOrder(orderId) {
    return getDb()
      .prepare('SELECT IFNULL(SUM(amount), 0) AS total FROM refunds WHERE order_id = ?')
      .get(orderId).total;
  },

  create({
    paymentId,
    orderId,
    amount,
    reason,
    refundedBy,
    shiftId,
    pointsReturned = 0,
    pointsValue = 0,
  }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO refunds
          (payment_id, order_id, amount, reason, refunded_by, shift_id, points_returned, points_value)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `,
      )
      .run(
        paymentId,
        orderId,
        amount,
        reason,
        refundedBy,
        shiftId ?? null,
        pointsReturned,
        pointsValue,
      );
    return this.findById(info.lastInsertRowid);
  },

  findById(id) {
    return getDb()
      .prepare(
        `
        SELECT r.*, u.name AS refunded_by_name, cn.id AS credit_note_id, cn.note_no AS credit_note_no
          FROM refunds r
          LEFT JOIN users u ON u.id = r.refunded_by
          LEFT JOIN credit_notes cn ON cn.refund_id = r.id
         WHERE r.id = ?
      `,
      )
      .get(id);
  },
};

export default refundRepository;
