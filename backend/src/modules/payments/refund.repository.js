import { getDb } from '../../db/index.js';

export const refundRepository = {
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

  totalByOrder(orderId) {
    return getDb()
      .prepare('SELECT IFNULL(SUM(amount), 0) AS total FROM refunds WHERE order_id = ?')
      .get(orderId).total;
  },

  create({ paymentId, orderId, amount, reason, refundedBy, shiftId }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO refunds (payment_id, order_id, amount, reason, refunded_by, shift_id)
        VALUES (?, ?, ?, ?, ?, ?)
      `,
      )
      .run(paymentId, orderId, amount, reason, refundedBy, shiftId ?? null);
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
