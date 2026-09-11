import { getDb } from '../../db/index.js';

const ORDER_SELECT = `
  SELECT o.*,
         t.name AS table_name,
         t.zone AS table_zone,
         u.name AS waiter_name
    FROM orders o
    LEFT JOIN dining_tables t ON t.id = o.table_id
    LEFT JOIN users u ON u.id = o.waiter_id
`;

export const orderRepository = {
  /** เลขที่ออเดอร์รูปแบบ ORD-YYYYMMDD-0001 (รันต่อวัน) */
  nextCode() {
    const today = new Date();
    const datePart = [
      today.getFullYear(),
      String(today.getMonth() + 1).padStart(2, '0'),
      String(today.getDate()).padStart(2, '0'),
    ].join('');
    const prefix = `ORD-${datePart}`;
    const last = getDb()
      .prepare('SELECT code FROM orders WHERE code LIKE ? ORDER BY id DESC LIMIT 1')
      .get(`${prefix}%`);
    const sequence = last ? Number(last.code.split('-')[2]) + 1 : 1;
    return `${prefix}-${String(sequence).padStart(4, '0')}`;
  },

  findAll({ status, statuses, tableId, waiterId, dateFrom, dateTo, page = 1, limit = 20 } = {}) {
    const clauses = [];
    const params = [];

    if (status) {
      clauses.push('o.status = ?');
      params.push(status);
    }
    if (statuses?.length) {
      clauses.push(`o.status IN (${statuses.map(() => '?').join(',')})`);
      params.push(...statuses);
    }
    if (tableId) {
      clauses.push('o.table_id = ?');
      params.push(tableId);
    }
    if (waiterId) {
      clauses.push('o.waiter_id = ?');
      params.push(waiterId);
    }
    if (dateFrom) {
      clauses.push('date(o.created_at) >= date(?)');
      params.push(dateFrom);
    }
    if (dateTo) {
      clauses.push('date(o.created_at) <= date(?)');
      params.push(dateTo);
    }

    const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
    const db = getDb();
    const total = db.prepare(`SELECT COUNT(*) AS c FROM orders o ${where}`).get(...params).c;
    const rows = db
      .prepare(`${ORDER_SELECT} ${where} ORDER BY o.created_at DESC, o.id DESC LIMIT ? OFFSET ?`)
      .all(...params, limit, (page - 1) * limit);

    return { rows, total };
  },

  findById(id) {
    return getDb().prepare(`${ORDER_SELECT} WHERE o.id = ?`).get(id);
  },

  findByCode(code) {
    return getDb().prepare(`${ORDER_SELECT} WHERE o.code = ?`).get(code);
  },

  findOpenByTable(tableId) {
    return getDb()
      .prepare(
        `${ORDER_SELECT} WHERE o.table_id = ? AND o.status IN ('open','in_kitchen','served') LIMIT 1`,
      )
      .get(tableId);
  },

  /** category_id มาจาก menu_items ปัจจุบัน (ไม่ใช่ snapshot) — ใช้ตอนจับคู่เงื่อนไขโปรโมชันตามหมวดหมู่ */
  findItems(orderId) {
    return getDb()
      .prepare(
        `
        SELECT oi.*, m.category_id AS category_id
          FROM order_items oi
          LEFT JOIN menu_items m ON m.id = oi.menu_item_id
         WHERE oi.order_id = ?
         ORDER BY oi.id
      `,
      )
      .all(orderId);
  },

  findItemsByStatuses(statuses) {
    const placeholders = statuses.map(() => '?').join(',');
    return getDb()
      .prepare(
        `
        SELECT oi.*, o.code AS order_code, o.type AS order_type, t.name AS table_name
          FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
          LEFT JOIN dining_tables t ON t.id = o.table_id
         WHERE oi.status IN (${placeholders})
           AND o.status IN ('in_kitchen', 'served')
         ORDER BY oi.created_at
      `,
      )
      .all(...statuses);
  },

  findItemById(itemId) {
    return getDb().prepare('SELECT * FROM order_items WHERE id = ?').get(itemId);
  },

  create({ code, type, tableId, waiterId, guestCount, note }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO orders (code, type, table_id, waiter_id, guest_count, note)
        VALUES (?, ?, ?, ?, ?, ?)
      `,
      )
      .run(code, type, tableId ?? null, waiterId ?? null, guestCount ?? 1, note ?? null);
    return this.findById(info.lastInsertRowid);
  },

  addItem(orderId, item) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO order_items
          (order_id, menu_item_id, name_snapshot, unit_price, quantity, options_json, options_price, line_total, note)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      )
      .run(
        orderId,
        item.menuItemId,
        item.nameSnapshot,
        item.unitPrice,
        item.quantity,
        JSON.stringify(item.options ?? []),
        item.optionsPrice,
        item.lineTotal,
        item.note ?? null,
      );
    return this.findItemById(info.lastInsertRowid);
  },

  updateItem(itemId, { quantity, note, lineTotal, status }) {
    getDb()
      .prepare(
        `
        UPDATE order_items
           SET quantity   = COALESCE(?, quantity),
               note       = COALESCE(?, note),
               line_total = COALESCE(?, line_total),
               status     = COALESCE(?, status),
               updated_at = datetime('now')
         WHERE id = ?
      `,
      )
      .run(quantity ?? null, note ?? null, lineTotal ?? null, status ?? null, itemId);
    return this.findItemById(itemId);
  },

  removeItem(itemId) {
    return getDb().prepare('DELETE FROM order_items WHERE id = ?').run(itemId).changes > 0;
  },

  markItemsStatus(orderId, fromStatus, toStatus) {
    return getDb()
      .prepare(
        "UPDATE order_items SET status = ?, updated_at = datetime('now') WHERE order_id = ? AND status = ?",
      )
      .run(toStatus, orderId, fromStatus).changes;
  },

  updateTotals(orderId, totals) {
    getDb()
      .prepare(
        `
        UPDATE orders
           SET subtotal                  = ?,
               discount_type             = ?,
               discount_value            = ?,
               discount_amount           = ?,
               promotion_id              = ?,
               promotion_name_snapshot   = ?,
               promotion_code_snapshot   = ?,
               promotion_discount_amount = ?,
               service_charge            = ?,
               vat                       = ?,
               total                     = ?,
               updated_at                = datetime('now')
         WHERE id = ?
      `,
      )
      .run(
        totals.subtotal,
        totals.discountType,
        totals.discountValue,
        totals.discountAmount,
        totals.promotionId ?? null,
        totals.promotionName ?? null,
        totals.promotionCode ?? null,
        totals.promotionDiscountAmount ?? 0,
        totals.serviceCharge,
        totals.vat,
        totals.total,
        orderId,
      );
  },

  updateStatus(orderId, status, { closedAt = null, cancelledReason = null } = {}) {
    getDb()
      .prepare(
        `
        UPDATE orders
           SET status           = ?,
               closed_at        = COALESCE(?, closed_at),
               cancelled_reason = COALESCE(?, cancelled_reason),
               updated_at       = datetime('now')
         WHERE id = ?
      `,
      )
      .run(status, closedAt, cancelledReason, orderId);
    return this.findById(orderId);
  },

  updateTable(orderId, tableId) {
    getDb()
      .prepare("UPDATE orders SET table_id = ?, updated_at = datetime('now') WHERE id = ?")
      .run(tableId, orderId);
    return this.findById(orderId);
  },

  /** ย้ายรายการอาหารทั้งหมดของออเดอร์หนึ่งไปอยู่ในอีกออเดอร์หนึ่ง (ใช้ตอนรวมบิล) */
  reassignItems(fromOrderId, toOrderId) {
    return getDb()
      .prepare(
        "UPDATE order_items SET order_id = ?, updated_at = datetime('now') WHERE order_id = ?",
      )
      .run(toOrderId, fromOrderId).changes;
  },

  markItemsPaid(itemIds) {
    if (!itemIds.length) return 0;
    const placeholders = itemIds.map(() => '?').join(',');
    return getDb()
      .prepare(
        `UPDATE order_items SET is_paid = 1, updated_at = datetime('now') WHERE id IN (${placeholders})`,
      )
      .run(...itemIds).changes;
  },

  updateMeta(orderId, { guestCount, note }) {
    getDb()
      .prepare(
        `
        UPDATE orders
           SET guest_count = COALESCE(?, guest_count),
               note        = COALESCE(?, note),
               updated_at  = datetime('now')
         WHERE id = ?
      `,
      )
      .run(guestCount ?? null, note ?? null, orderId);
    return this.findById(orderId);
  },
};

export default orderRepository;
