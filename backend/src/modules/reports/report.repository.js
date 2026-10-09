// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

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

/**
 * แยกเงินคืนแต่ละรายการของออเดอร์ที่จ่ายครบ (`paid`) เป็นส่วนที่คืน "ก่อนบิลปิด" กับ "หลังบิลปิด" (#143, docs/DECISIONS.md #97)
 *
 * บิลปิดได้เมื่อยอดชำระ − ยอดคืนเท่ากับยอดบิลพอดี (T06, DECISIONS #87 — รับเงินเกินยอดคงเหลือไม่ได้ และหลังบิลปิดรับเงินเพิ่มไม่ได้)
 * เงินที่คืนก่อนปิดจึงรวมได้ ยอดชำระทั้งหมด − ยอดบิล เสมอ คืนรายการแรกๆ ตามลำดับ id ไปจนครบก้อนนั้นคือคืนก่อนปิด
 * ที่เหลือคือคืนหลังปิด ไม่เทียบ `refunds.created_at` กับ `orders.closed_at` เพราะทั้งสองละเอียดแค่วินาที
 * การคืนแล้วเก็บเงินจนบิลปิดในวินาทีเดียวกันจะแยกไม่ออก
 *
 * - `post_amount` ลดยอดขาย (คืนสินค้า/คืนเงินหลังขายแล้ว)
 * - `pre_amount` เป็นเงินที่ร้านเก็บกลับมาแล้วก่อนปิดบิล ไม่ลดยอดขาย แต่หักออกจากยอดของ payment นั้นในช่องทางชำระเงิน
 *   `pre_points` คือส่วนของ `pre_amount` ที่คืนเป็นแต้ม (T11 #101, DECISIONS #100)
 * ออเดอร์ที่ไม่ใช่ `paid` (ยกเลิก หรือยังเปิดอยู่) ไม่อยู่ในชุดนี้ เพราะไม่ใช่ยอดขาย
 */
const PAID_REFUNDS_CTE = `
  paid_refund_split AS (
    SELECT r.id, r.payment_id, r.order_id, r.amount, r.points_value, r.created_at,
           SUM(r.amount) OVER (PARTITION BY r.order_id ORDER BY r.id) AS running,
           MAX((SELECT IFNULL(SUM(p.amount), 0) FROM payments p WHERE p.order_id = o.id) - o.total, 0)
             AS refunded_before_close
      FROM refunds r
      JOIN orders o ON o.id = r.order_id
     WHERE o.status = 'paid'
  ),
  paid_refunds AS (
    SELECT id, payment_id, order_id, created_at,
           MIN(amount, MAX(running - refunded_before_close, 0)) AS post_amount,
           amount - MIN(amount, MAX(running - refunded_before_close, 0)) AS pre_amount,
           points_value * (amount - MIN(amount, MAX(running - refunded_before_close, 0))) / amount
             AS pre_points
      FROM paid_refund_split
  ),
  pre_close_by_payment AS (
    SELECT payment_id, SUM(pre_amount) AS pre_amount, SUM(pre_points) AS pre_points
      FROM paid_refunds
     GROUP BY payment_id
  )`;

/**
 * ยอดต่อช่องทางชำระเงินของ payment ในออเดอร์ที่ `paid` หักเงินที่คืนก่อนบิลปิดแล้ว — คือเงินที่ร้านเก็บไว้ตอนบิลปิด
 * รวมกันได้ยอดบิล ฐานเดียวกับยอดขายสุทธิ payment ที่ถูกคืนครบก่อนปิดบิลไม่นับเป็นรายการ
 *
 * ยอดของแต่ละช่องทางเป็นเงินที่รับจริง (ยอดชำระ − มูลค่าแต้มที่ใช้แลก) ส่วนแต้มแยกเป็นบรรทัด `points` ของตัวเอง
 * (T11 #101, DECISIONS #100) เงินสดในรายงานจึงตรงกับเงินในลิ้นชัก
 */
const netPaymentMethodsSql = (where) => `
  WITH ${PAID_REFUNDS_CTE},
  net_payments AS (
    SELECT p.method,
           (p.amount - p.points_redeemed_value)
             - IFNULL(pc.pre_amount - pc.pre_points, 0) AS money,
           p.points_redeemed_value - IFNULL(pc.pre_points, 0) AS points_value
      FROM payments p
      JOIN orders o ON o.id = p.order_id
      LEFT JOIN pre_close_by_payment pc ON pc.payment_id = p.id
     WHERE o.status = 'paid'
       ${where}
  )
  SELECT method, count, amount FROM (
    SELECT method,
           SUM(CASE WHEN money > 0 THEN 1 ELSE 0 END) AS count,
           IFNULL(SUM(money), 0) AS amount
      FROM net_payments
     GROUP BY method
    UNION ALL
    SELECT 'points',
           SUM(CASE WHEN points_value > 0 THEN 1 ELSE 0 END),
           IFNULL(SUM(points_value), 0)
      FROM net_payments
  )
   WHERE count > 0
   ORDER BY amount DESC
`;

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
         WHERE status = 'paid'
           AND id IN (SELECT DISTINCT order_id FROM payments WHERE shift_id = ?)
      `,
      )
      .get(shiftId);
  },

  shiftRefundTotal(shiftId) {
    return getDb()
      .prepare(
        `
        WITH ${PAID_REFUNDS_CTE}
        SELECT IFNULL(SUM(r.post_amount), 0) AS total
          FROM paid_refunds r
          JOIN payments p ON p.id = r.payment_id
         WHERE p.shift_id = ?
      `,
      )
      .get(shiftId).total;
  },

  byShiftPaymentMethod(shiftId) {
    return getDb().prepare(netPaymentMethodsSql('AND p.shift_id = ?')).all(shiftId);
  },

  refundTotal(from, to, branchId) {
    const [start, end] = dateRange(from, to);
    return getDb()
      .prepare(
        `
        WITH ${PAID_REFUNDS_CTE}
        SELECT IFNULL(SUM(r.post_amount), 0) AS total
          FROM paid_refunds r
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
        netPaymentMethodsSql(
          `AND date(p.created_at) BETWEEN date(?) AND date(?) ${branchClause('o.branch_id', branchId)}`,
        ),
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
