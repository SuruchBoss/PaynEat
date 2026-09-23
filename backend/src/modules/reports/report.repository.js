import { getDb } from '../../db/index.js';

const dateRange = (from, to) => [from ?? '1970-01-01', to ?? '2999-12-31'];

// branchId เป็น null/undefined เฉพาะ admin โหมด "ทุกสาขา" (ดู docs/DECISIONS.md #36) — ไม่กรองเลย
// จึงเห็นยอดรวมทุกสาขา (ตอบโจทย์ "owner/admin ระดับองค์กรดูรายงานสรุปรวมทุกสาขาได้")
//
// ต่อ string เข้า SQL ตรงๆ แทนที่จะ bind เป็น `?` เหมือนพารามิเตอร์อื่นในไฟล์นี้ เพราะ query หลาย
// ตัวมี `?` ของ LIMIT/other params ต่อท้าย WHERE อยู่แล้ว การแทรก `?` เพิ่มตรงกลางจะทำให้ตำแหน่ง
// พารามิเตอร์เพี้ยนเมื่อ branchId เป็น null (ไม่มี `?` ให้ bind แต่ยังต้องส่ง arg ตำแหน่งเดิม) —
// ปลอดภัยเพราะ branchId มาจาก req.branchId ที่ถอดจาก JWT payload เท่านั้น (เป็น number|null เสมอ
// ไม่ใช่ string จาก request โดยตรง) และตรวจซ้ำด้วย Number.isInteger ก่อนแทรกเสมอ
const branchClause = (column, branchId) => {
  if (branchId === null || branchId === undefined) return '';
  if (!Number.isInteger(branchId)) throw new TypeError('branchId ต้องเป็นเลขจำนวนเต็มหรือ null');
  return `AND ${column} = ${branchId}`;
};

export const reportRepository = {
  salesSummary(from, to, branchId) {
    const [start, end] = dateRange(from, to);
    return getDb()
      .prepare(
        `
        SELECT COUNT(*)                      AS order_count,
               IFNULL(SUM(subtotal), 0)      AS subtotal,
               IFNULL(SUM(discount_amount), 0) AS discount,
               IFNULL(SUM(promotion_discount_amount), 0) AS promotion_discount,
               IFNULL(SUM(service_charge), 0)  AS service_charge,
               IFNULL(SUM(vat), 0)           AS vat,
               IFNULL(SUM(total), 0)         AS total,
               IFNULL(SUM(guest_count), 0)   AS guests
          FROM orders
         WHERE status = 'paid'
           AND date(created_at) BETWEEN date(?) AND date(?)
           ${branchClause('branch_id', branchId)}
      `,
      )
      .get(start, end);
  },

  /** ยอดออเดอร์ที่ถูกจ่ายในกะนี้ (dedupe ผ่าน payments.shift_id เพราะแยกจ่ายได้หลาย payment
   * ต่อออเดอร์เดียว) ใช้ประกอบ Z-report ต่อกะ — ดู docs/tickets/12-report-export.md
   * (กะไม่ผูก branch_id ตั้งใจไว้ — ดู docs/DECISIONS.md #36 — จึงไม่กรองตามสาขาที่นี่) */
  shiftOrdersSummary(shiftId) {
    return getDb()
      .prepare(
        `
        SELECT COUNT(*)                      AS order_count,
               IFNULL(SUM(subtotal), 0)      AS subtotal,
               IFNULL(SUM(discount_amount), 0) AS discount,
               IFNULL(SUM(promotion_discount_amount), 0) AS promotion_discount,
               IFNULL(SUM(service_charge), 0)  AS service_charge,
               IFNULL(SUM(vat), 0)           AS vat,
               IFNULL(SUM(total), 0)         AS total,
               IFNULL(SUM(guest_count), 0)   AS guests
          FROM orders
         WHERE id IN (SELECT DISTINCT order_id FROM payments WHERE shift_id = ?)
      `,
      )
      .get(shiftId);
  },

  shiftRefundTotal(shiftId) {
    return getDb()
      .prepare(
        `
        SELECT IFNULL(SUM(r.amount), 0) AS total
          FROM refunds r
          JOIN payments p ON p.id = r.payment_id
         WHERE p.shift_id = ?
      `,
      )
      .get(shiftId).total;
  },

  byShiftPaymentMethod(shiftId) {
    return getDb()
      .prepare(
        `
        SELECT method, COUNT(*) AS count, IFNULL(SUM(amount), 0) AS amount
          FROM payments
         WHERE shift_id = ?
         GROUP BY method
         ORDER BY amount DESC
      `,
      )
      .all(shiftId);
  },

  refundTotal(from, to, branchId) {
    const [start, end] = dateRange(from, to);
    return getDb()
      .prepare(
        `
        SELECT IFNULL(SUM(r.amount), 0) AS total
          FROM refunds r
          JOIN orders o ON o.id = r.order_id
         WHERE date(r.created_at) BETWEEN date(?) AND date(?)
           ${branchClause('o.branch_id', branchId)}
      `,
      )
      .get(start, end).total;
  },

  byPaymentMethod(from, to, branchId) {
    const [start, end] = dateRange(from, to);
    return getDb()
      .prepare(
        `
        SELECT p.method, COUNT(*) AS count, IFNULL(SUM(p.amount), 0) AS amount
          FROM payments p
          JOIN orders o ON o.id = p.order_id
         WHERE o.status = 'paid'
           AND date(p.created_at) BETWEEN date(?) AND date(?)
           ${branchClause('o.branch_id', branchId)}
         GROUP BY p.method
         ORDER BY amount DESC
      `,
      )
      .all(start, end);
  },

  topItems(from, to, limit = 10, branchId) {
    const [start, end] = dateRange(from, to);
    return getDb()
      .prepare(
        `
        SELECT oi.menu_item_id,
               oi.name_snapshot            AS name,
               SUM(oi.quantity)            AS quantity,
               IFNULL(SUM(oi.weight_grams), 0) AS weight_grams,
               IFNULL(SUM(oi.line_total), 0) AS revenue
          FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
         WHERE o.status = 'paid'
           AND oi.status <> 'cancelled'
           AND date(o.created_at) BETWEEN date(?) AND date(?)
           ${branchClause('o.branch_id', branchId)}
         GROUP BY oi.name_snapshot
         ORDER BY quantity DESC, revenue DESC
         LIMIT ?
      `,
      )
      .all(start, end, limit);
  },

  salesByDay(from, to, branchId) {
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
           ${branchClause('branch_id', branchId)}
         GROUP BY day
         ORDER BY day
      `,
      )
      .all(start, end);
  },

  salesByHour(day, branchId) {
    return getDb()
      .prepare(
        `
        SELECT strftime('%H', created_at) AS hour,
               COUNT(*)                   AS order_count,
               IFNULL(SUM(total), 0)      AS total
          FROM orders
         WHERE status = 'paid' AND date(created_at) = date(?)
           ${branchClause('branch_id', branchId)}
         GROUP BY hour
         ORDER BY hour
      `,
      )
      .all(day);
  },

  byCategory(from, to, branchId) {
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
           ${branchClause('o.branch_id', branchId)}
         GROUP BY category
         ORDER BY revenue DESC
      `,
      )
      .all(start, end);
  },

  liveCounters(branchId) {
    const db = getDb();
    return {
      openOrders: db
        .prepare(
          `
          SELECT COUNT(*) AS c FROM orders
           WHERE status IN ('open','in_kitchen','served') ${branchClause('branch_id', branchId)}
        `,
        )
        .get().c,
      occupiedTables: db
        .prepare(
          `
          SELECT COUNT(*) AS c FROM dining_tables
           WHERE status = 'occupied' ${branchClause('branch_id', branchId)}
        `,
        )
        .get().c,
      totalTables: db
        .prepare(
          `
          SELECT COUNT(*) AS c FROM dining_tables
           WHERE is_active = 1 ${branchClause('branch_id', branchId)}
        `,
        )
        .get().c,
      pendingKitchenItems: db
        .prepare(
          `
          SELECT COUNT(*) AS c
            FROM order_items oi
            JOIN orders o ON o.id = oi.order_id
           WHERE oi.status IN ('pending','cooking')
             AND o.status IN ('in_kitchen','served')
             ${branchClause('o.branch_id', branchId)}
        `,
        )
        .get().c,
    };
  },
};

export default reportRepository;
