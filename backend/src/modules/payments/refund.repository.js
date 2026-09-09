import { getDb } from '../../db/index.js';

export const refundRepository = {
  findByOrder(orderId) {
    return getDb()
      .prepare(
        `
        SELECT r.*, u.name AS refunded_by_name
          FROM refunds r
          LEFT JOIN users u ON u.id = r.refunded_by
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

  create({ paymentId, orderId, amount, reason, refundedBy }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO refunds (payment_id, order_id, amount, reason, refunded_by)
        VALUES (?, ?, ?, ?, ?)
      `,
      )
      .run(paymentId, orderId, amount, reason, refundedBy);
    return getDb()
      .prepare(
        `
        SELECT r.*, u.name AS refunded_by_name
          FROM refunds r
          LEFT JOIN users u ON u.id = r.refunded_by
         WHERE r.id = ?
      `,
      )
      .get(info.lastInsertRowid);
  },
};

export default refundRepository;
