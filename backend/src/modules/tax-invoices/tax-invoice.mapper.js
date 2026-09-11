import { toBaht } from '../../core/money.js';

export const toTaxInvoiceDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    orderId: row.order_id,
    orderCode: row.order_code,
    runningNumber: row.running_number,
    invoiceType: row.invoice_type,
    customerName: row.customer_name,
    customerAddress: row.customer_address,
    customerTaxId: row.customer_tax_id,
    storeName: row.store_name,
    storeTaxId: row.store_tax_id,
    storeAddress: row.store_address,
    storeBranch: row.store_branch,
    subtotal: toBaht(row.subtotal),
    vat: toBaht(row.vat),
    total: toBaht(row.total),
    issuedBy: row.issued_by,
    issuedByName: row.issued_by_name,
    issuedAt: row.issued_at,
    isVoid: Boolean(row.voided_at),
    voidedAt: row.voided_at,
    voidReason: row.void_reason,
    voidedBy: row.voided_by,
    voidedByName: row.voided_by_name,
  };
};

export default toTaxInvoiceDto;
