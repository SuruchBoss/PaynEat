// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { getDb } from '../../db/index.js';

const SELECT = `
  SELECT cn.*, c.name AS customer_name, o.code AS order_code, p.created_at AS invoice_date,
         u.name AS issued_by_name
    FROM credit_notes cn
    JOIN customers c ON c.id = cn.customer_id
    JOIN orders o ON o.id = cn.order_id
    JOIN payments p ON p.id = cn.payment_id
    LEFT JOIN users u ON u.id = cn.issued_by
`;

/** ใบลดหนี้ของบิลขายเชื่อ (ดู docs/DECISIONS.md #56) */
export const creditNoteRepository = {
  create({
    noteNo,
    customerId,
    paymentId,
    refundId,
    orderId,
    originalAmount,
    previousCredited,
    amount,
    vatAmount,
    taxInvoiceNo,
    reason,
    issuedBy,
  }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO credit_notes
          (note_no, customer_id, payment_id, refund_id, order_id, original_amount,
           previous_credited, amount, vat_amount, tax_invoice_no, reason, issued_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      )
      .run(
        noteNo,
        customerId,
        paymentId,
        refundId,
        orderId,
        originalAmount,
        previousCredited,
        amount,
        vatAmount,
        taxInvoiceNo ?? null,
        reason,
        issuedBy,
      );
    return this.findById(info.lastInsertRowid);
  },

  findById(id) {
    return getDb().prepare(`${SELECT} WHERE cn.id = ?`).get(id);
  },

  findByRefundId(refundId) {
    return getDb().prepare(`${SELECT} WHERE cn.refund_id = ?`).get(refundId);
  },

  byCustomer(customerId) {
    return getDb()
      .prepare(`${SELECT} WHERE cn.customer_id = ? ORDER BY cn.id DESC`)
      .all(customerId);
  },
};

export default creditNoteRepository;
