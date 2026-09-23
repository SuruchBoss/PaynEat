import { toBaht } from '../../core/money.js';

export const toRefundDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    paymentId: row.payment_id,
    orderId: row.order_id,
    amount: toBaht(row.amount),
    reason: row.reason,
    refundedBy: row.refunded_by,
    refundedByName: row.refunded_by_name,
    createdAt: row.created_at,
    // ลดหนี้บิลขายเชื่อได้ใบลดหนี้เสมอ (DECISIONS #56) — คืนเงินบิลปกติเป็น null
    creditNoteId: row.credit_note_id ?? null,
    creditNoteNo: row.credit_note_no ?? null,
  };
};

export default toRefundDto;
