import { toBaht } from '../../core/money.js';

export const toPaymentDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    orderId: row.order_id,
    shiftId: row.shift_id,
    method: row.method,
    amount: toBaht(row.amount),
    received: toBaht(row.received),
    change: toBaht(row.change_amount),
    reference: row.reference,
    cashierId: row.cashier_id,
    cashierName: row.cashier_name,
    pointsRedeemed: row.points_redeemed ?? 0,
    pointsRedeemedValue: toBaht(row.points_redeemed_value ?? 0),
    createdAt: row.created_at,
  };
};

export default toPaymentDto;
