import { toBaht } from '../../core/money.js';

export const toOrderItemDto = (row) => {
  if (!row) return null;
  let options = [];
  try {
    options = JSON.parse(row.options_json ?? '[]');
  } catch {
    options = [];
  }

  return {
    id: row.id,
    orderId: row.order_id,
    menuItemId: row.menu_item_id,
    name: row.name_snapshot,
    unitPrice: toBaht(row.unit_price),
    quantity: row.quantity,
    options: options.map((option) => ({ ...option, priceDelta: toBaht(option.priceDelta ?? 0) })),
    optionsPrice: toBaht(row.options_price),
    lineTotal: toBaht(row.line_total),
    note: row.note,
    status: row.status,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    // เผื่อกรณีดึงมาจากคิวครัวที่ join ข้อมูลออเดอร์มาด้วย
    orderCode: row.order_code,
    tableName: row.table_name,
    orderType: row.order_type,
  };
};

export const toOrderDto = (row, items = []) => {
  if (!row) return null;
  return {
    id: row.id,
    code: row.code,
    type: row.type,
    tableId: row.table_id,
    tableName: row.table_name,
    tableZone: row.table_zone,
    waiterId: row.waiter_id,
    waiterName: row.waiter_name,
    guestCount: row.guest_count,
    status: row.status,
    note: row.note,
    subtotal: toBaht(row.subtotal),
    discountType: row.discount_type,
    discountValue:
      row.discount_type === 'percent' ? row.discount_value / 100 : toBaht(row.discount_value),
    discountAmount: toBaht(row.discount_amount),
    serviceCharge: toBaht(row.service_charge),
    vat: toBaht(row.vat),
    total: toBaht(row.total),
    cancelledReason: row.cancelled_reason,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    closedAt: row.closed_at,
    items: items.map(toOrderItemDto),
    itemCount: items.filter((item) => item.status !== 'cancelled').length,
  };
};
