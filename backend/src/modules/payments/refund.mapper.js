// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { toBaht } from '../../core/money.js';

export const toRefundDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    paymentId: row.payment_id,
    orderId: row.order_id,
    amount: toBaht(row.amount),
    // ยอดคืนแบ่งเป็นเงินที่ออกจากช่องทางจริงกับแต้มที่คืนให้ลูกค้า (T11 #101, DECISIONS #99)
    cashAmount: toBaht(row.amount - (row.points_value ?? 0)),
    pointsReturned: row.points_returned ?? 0,
    pointsValue: toBaht(row.points_value ?? 0),
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
