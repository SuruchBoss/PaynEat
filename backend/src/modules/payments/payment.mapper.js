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
    createdAt: row.created_at,
  };
};

export default toPaymentDto;
