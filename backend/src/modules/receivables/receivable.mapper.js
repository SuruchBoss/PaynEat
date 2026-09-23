import { toBaht } from '../../core/money.js';

const DAY_MS = 24 * 60 * 60 * 1000;

/** จำนวนวันที่เกินกำหนด (0 ถ้ายังไม่ถึงกำหนดหรือไม่มียอดค้างแล้ว) — วันที่เป็น YYYY-MM-DD ทั้งคู่ */
export const daysOverdue = (dueDate, today, outstanding) => {
  if (!dueDate || outstanding <= 0) return 0;
  const days = Math.round((Date.parse(today) - Date.parse(dueDate)) / DAY_MS);
  return days > 0 ? days : 0;
};

export const toInvoiceDto = (row, today) => {
  const overdueDays = daysOverdue(row.due_date, today, row.outstanding);
  return {
    paymentId: row.payment_id,
    orderId: row.order_id,
    orderCode: row.order_code,
    amount: toBaht(row.amount),
    refunded: toBaht(row.refunded),
    settled: toBaht(row.settled),
    outstanding: toBaht(Math.max(row.outstanding, 0)),
    createdAt: row.created_at,
    dueDate: row.due_date,
    daysOverdue: overdueDays,
    isOverdue: overdueDays > 0,
    billingNoteNo: row.billing_note_no ?? null,
  };
};

const toLineDto = (row) => ({
  paymentId: row.payment_id,
  orderCode: row.order_code,
  amount: toBaht(row.amount),
  createdAt: row.created_at,
  dueDate: row.due_date,
});

export const toReceiptDto = (row, allocations = []) => {
  if (!row) return null;
  return {
    id: row.id,
    receiptNo: row.receipt_no,
    customerId: row.customer_id,
    customerName: row.customer_name,
    amount: toBaht(row.amount),
    method: row.method,
    reference: row.reference,
    note: row.note,
    shiftId: row.shift_id,
    receivedByName: row.received_by_name,
    receivedAt: row.received_at,
    isVoided: Boolean(row.voided_at),
    voidedAt: row.voided_at,
    voidReason: row.void_reason,
    voidedByName: row.voided_by_name ?? null,
    allocations: allocations.map(toLineDto),
  };
};

export const toBillingNoteDto = (row, items = [], remainingSatang = 0) => {
  if (!row) return null;
  const isVoided = Boolean(row.voided_at);
  return {
    id: row.id,
    noteNo: row.note_no,
    customerId: row.customer_id,
    customerName: row.customer_name,
    total: toBaht(row.total),
    // ยอดที่ยังต้องเก็บจากบิลในใบวางบิลนี้ตอนนี้ (ลดลงตามที่รับชำระ/คืนเงิน) — total คือยอด ณ วันที่ออก
    remaining: toBaht(isVoided ? 0 : remainingSatang),
    status: isVoided ? 'void' : remainingSatang > 0 ? 'open' : 'paid',
    dueDate: row.due_date,
    note: row.note,
    issuedByName: row.issued_by_name,
    issuedAt: row.issued_at,
    isVoided,
    voidedAt: row.voided_at,
    voidReason: row.void_reason,
    voidedByName: row.voided_by_name ?? null,
    items: items.map(toLineDto),
  };
};
