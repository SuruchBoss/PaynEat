import { getDb } from '../../db/index.js';

export const paymentRepository = {
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

  totalPaid(orderId) {
    return getDb()
      .prepare('SELECT IFNULL(SUM(amount), 0) AS total FROM payments WHERE order_id = ?')
      .get(orderId).total;
  },

  create({ orderId, shiftId, method, amount, received, changeAmount, reference, cashierId }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO payments (order_id, shift_id, method, amount, received, change_amount, reference, cashier_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
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
      );
    return this.findById(info.lastInsertRowid);
  },
};

export default paymentRepository;
