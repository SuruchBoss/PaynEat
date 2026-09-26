// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { getDb } from '../../db/index.js';

const CHARGE_SELECT = `
  SELECT ch.*, c.name AS customer_name, u.name AS issued_by_name, v.name AS voided_by_name
    FROM ar_charges ch
    JOIN customers c ON c.id = ch.customer_id
    LEFT JOIN users u ON u.id = ch.issued_by
    LEFT JOIN users v ON v.id = ch.voided_by
`;

/** ใบแจ้งดอกเบี้ยผิดนัด (ar_charges) + บรรทัดต่อบิล (ar_charge_items) — ดู docs/DECISIONS.md #55 */
export const lateFeeRepository = {
  create({ chargeNo, customerId, total, annualRate, asOf, note, issuedBy }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO ar_charges (charge_no, customer_id, total, annual_rate, as_of, note, issued_by)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `,
      )
      .run(chargeNo, customerId, total, annualRate, asOf, note ?? null, issuedBy);
    return this.findById(info.lastInsertRowid);
  },

  addItem({ chargeId, paymentId, principal, periodFrom, periodTo, days, amount }) {
    getDb()
      .prepare(
        `
        INSERT INTO ar_charge_items
          (charge_id, payment_id, principal, period_from, period_to, days, amount)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `,
      )
      .run(chargeId, paymentId, principal, periodFrom, periodTo, days, amount);
  },

  findById(id) {
    return getDb().prepare(`${CHARGE_SELECT} WHERE ch.id = ?`).get(id);
  },

  byCustomer(customerId) {
    return getDb()
      .prepare(`${CHARGE_SELECT} WHERE ch.customer_id = ? ORDER BY ch.id DESC`)
      .all(customerId);
  },

  items(chargeId) {
    return getDb()
      .prepare(
        `
        SELECT ci.*, p.order_id, o.code AS order_code, p.due_date
          FROM ar_charge_items ci
          JOIN payments p ON p.id = ci.payment_id
          JOIN orders o ON o.id = p.order_id
         WHERE ci.charge_id = ?
         ORDER BY p.due_date, p.id
      `,
      )
      .all(chargeId);
  },

  void(id, { reason, voidedBy }) {
    getDb()
      .prepare(
        "UPDATE ar_charges SET voided_at = datetime('now'), void_reason = ?, voided_by = ? WHERE id = ?",
      )
      .run(reason, voidedBy, id);
    return this.findById(id);
  },
};

export default lateFeeRepository;
