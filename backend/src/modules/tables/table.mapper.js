import { toBaht } from '../../core/money.js';

export const toTableDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    zone: row.zone,
    seats: row.seats,
    status: row.status,
    isActive: Boolean(row.is_active),
    currentOrder: row.order_id
      ? {
          id: row.order_id,
          code: row.order_code,
          status: row.order_status,
          total: toBaht(row.order_total),
          guestCount: row.order_guest_count,
          createdAt: row.order_created_at,
        }
      : null,
  };
};

export default toTableDto;
