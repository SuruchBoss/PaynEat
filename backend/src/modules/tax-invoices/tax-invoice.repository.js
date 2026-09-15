import { getDb } from '../../db/index.js';

const SELECT = `
  SELECT ti.*,
         o.code AS order_code,
         issuer.name AS issued_by_name,
         voider.name AS voided_by_name
    FROM tax_invoices ti
    JOIN orders o ON o.id = ti.order_id
    JOIN users issuer ON issuer.id = ti.issued_by
    LEFT JOIN users voider ON voider.id = ti.voided_by
`;

export const taxInvoiceRepository = {
  findById(id) {
    return getDb().prepare(`${SELECT} WHERE ti.id = ?`).get(id);
  },

  /** ใบกำกับภาษีที่ยัง active อยู่ (ยังไม่ถูกยกเลิก) ของออเดอร์นี้ — มีได้สูงสุด 1 ใบเสมอ */
  findActiveByOrder(orderId) {
    return getDb().prepare(`${SELECT} WHERE ti.order_id = ? AND ti.voided_at IS NULL`).get(orderId);
  },

  /** จำนวนใบกำกับภาษี (รวมที่ถูกยกเลิกแล้ว) ที่เคยออกด้วย prefix นี้ — ใช้คำนวณเลขที่ถัดไป */
  countByRunningNumberPrefix(prefix) {
    return getDb()
      .prepare('SELECT COUNT(*) AS c FROM tax_invoices WHERE running_number LIKE ?')
      .get(`${prefix}%`).c;
  },

  create(payload) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO tax_invoices (
          order_id, running_number, invoice_type,
          customer_name, customer_address, customer_tax_id,
          store_name, store_tax_id, store_address, store_branch,
          subtotal, vat, total, issued_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      )
      .run(
        payload.orderId,
        payload.runningNumber,
        payload.invoiceType,
        payload.customerName ?? null,
        payload.customerAddress ?? null,
        payload.customerTaxId ?? null,
        payload.storeName,
        payload.storeTaxId,
        payload.storeAddress,
        payload.storeBranch ?? null,
        payload.subtotal,
        payload.vat,
        payload.total,
        payload.issuedBy,
      );
    return this.findById(info.lastInsertRowid);
  },

  void(id, { reason, voidedBy }) {
    getDb()
      .prepare(
        `
        UPDATE tax_invoices
           SET voided_at = datetime('now'), void_reason = ?, voided_by = ?
         WHERE id = ?
      `,
      )
      .run(reason, voidedBy, id);
    return this.findById(id);
  },
};

export default taxInvoiceRepository;
