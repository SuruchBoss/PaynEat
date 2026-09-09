import { getDb } from '../../db/index.js';

const dateRange = (from, to) => [from ?? '1970-01-01', to ?? '2999-12-31'];

export const reportRepository = {
  salesSummary(from, to) {
    const [start, end] = dateRange(from, to);
    return getDb()
      .prepare(
        `
        SELECT COUNT(*)                      AS order_count,
               IFNULL(SUM(subtotal), 0)      AS subtotal,
               IFNULL(SUM(discount_amount), 0) AS discount,
               IFNULL(SUM(service_charge), 0)  AS service_charge,
               IFNULL(SUM(vat), 0)           AS vat,
               IFNULL(SUM(total), 0)         AS total,
               IFNULL(SUM(guest_count), 0)   AS guests
          FROM orders
         WHERE status = 'paid'
           AND date(created_at) BETWEEN date(?) AND date(?)
      `,
      )
      .get(start, end);
  },

  refundTotal(from, to) {
    const [start, end] = dateRange(from, to);
    return getDb()
      .prepare(
        `
        SELECT IFNULL(SUM(amount), 0) AS total
          FROM refunds
         WHERE date(created_at) BETWEEN date(?) AND date(?)
      `,
      )
      .get(start, end).total;
  },

  byPaymentMethod(from, to) {
    const [start, end] = dateRange(from, to);
    return getDb()
      .prepare(
        `
        SELECT p.method, COUNT(*) AS count, IFNULL(SUM(p.amount), 0) AS amount
          FROM payments p
          JOIN orders o ON o.id = p.order_id
         WHERE o.status = 'paid'
           AND date(p.created_at) BETWEEN date(?) AND date(?)
         GROUP BY p.method
         ORDER BY amount DESC
      `,
      )
      .all(start, end);
  },

  topItems(from, to, limit = 10) {
    const [start, end] = dateRange(from, to);
    return getDb()
      .prepare(
        `
        SELECT oi.menu_item_id,
               oi.name_snapshot            AS name,
               SUM(oi.quantity)            AS quantity,
               IFNULL(SUM(oi.line_total), 0) AS revenue
          FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
         WHERE o.status = 'paid'
           AND oi.status <> 'cancelled'
           AND date(o.created_at) BETWEEN date(?) AND date(?)
         GROUP BY oi.name_snapshot
         ORDER BY quantity DESC, revenue DESC
         LIMIT ?
      `,
      )
      .all(start, end, limit);
  },

  salesByDay(from, to) {
    const [start, end] = dateRange(from, to);
    return getDb()
      .prepare(
        `
        SELECT date(created_at)      AS day,
               COUNT(*)              AS order_count,
               IFNULL(SUM(total), 0) AS total
          FROM orders
         WHERE status = 'paid'
           AND date(created_at) BETWEEN date(?) AND date(?)
         GROUP BY day
         ORDER BY day
      `,
      )
      .all(start, end);
  },

  salesByHour(day) {
    return getDb()
      .prepare(
        `
        SELECT strftime('%H', created_at) AS hour,
               COUNT(*)                   AS order_count,
               IFNULL(SUM(total), 0)      AS total
          FROM orders
         WHERE status = 'paid' AND date(created_at) = date(?)
         GROUP BY hour
         ORDER BY hour
      `,
      )
      .all(day);
  },

  byCategory(from, to) {
    const [start, end] = dateRange(from, to);
    return getDb()
      .prepare(
        `
        SELECT IFNULL(c.name, 'ไม่ระบุหมวดหมู่') AS category,
               SUM(oi.quantity)                  AS quantity,
               IFNULL(SUM(oi.line_total), 0)     AS revenue
          FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
          LEFT JOIN menu_items m ON m.id = oi.menu_item_id
          LEFT JOIN categories c ON c.id = m.category_id
         WHERE o.status = 'paid'
           AND oi.status <> 'cancelled'
           AND date(o.created_at) BETWEEN date(?) AND date(?)
         GROUP BY category
         ORDER BY revenue DESC
      `,
      )
      .all(start, end);
  },

  liveCounters() {
    const db = getDb();
    return {
      openOrders: db
        .prepare("SELECT COUNT(*) AS c FROM orders WHERE status IN ('open','in_kitchen','served')")
        .get().c,
      occupiedTables: db
        .prepare("SELECT COUNT(*) AS c FROM dining_tables WHERE status = 'occupied'")
        .get().c,
      totalTables: db.prepare('SELECT COUNT(*) AS c FROM dining_tables WHERE is_active = 1').get()
        .c,
      pendingKitchenItems: db
        .prepare(
          `
          SELECT COUNT(*) AS c
            FROM order_items oi
            JOIN orders o ON o.id = oi.order_id
           WHERE oi.status IN ('pending','cooking')
             AND o.status IN ('in_kitchen','served')
        `,
        )
        .get().c,
    };
  },
};

export default reportRepository;
