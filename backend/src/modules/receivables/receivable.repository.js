import { getDb } from '../../db/index.js';

/**
 * "ใบแจ้งหนี้" หนึ่งใบคือ payments แถวที่ method = 'credit' (ดู docs/DECISIONS.md #50) — ยอดคืนเงิน
 * และยอดที่ตัดชำระแล้วคำนวณสดทุกครั้งจากตารางต้นทาง ไม่เก็บ "ยอดค้าง" แยกไว้ ตัวเลขจึงไม่มีทางเพี้ยน
 * จากกันเวลามีคนคืนเงินหรือยกเลิกใบเสร็จ (ใบเสร็จที่ถูกยกเลิกไม่นับ)
 *
 * ดอกเบี้ยผิดนัด (charged) บวกเข้ายอดค้างของบิลนั้นเลย (DECISIONS #55) — ใบแจ้งดอกเบี้ยที่ถูกยกเลิกไม่นับ
 * และ interest_through คือวันสุดท้ายที่คิดดอกเบี้ยไปแล้ว รอบถัดไปเริ่มนับวันถัดจากนี้
 */
const INVOICE_SELECT = `
  SELECT p.id         AS payment_id,
         p.order_id,
         o.code       AS order_code,
         o.customer_id,
         p.amount,
         p.created_at,
         p.due_date,
         IFNULL((SELECT SUM(r.amount) FROM refunds r WHERE r.payment_id = p.id), 0) AS refunded,
         IFNULL((SELECT SUM(a.amount)
                   FROM ar_allocations a
                   JOIN ar_receipts rc ON rc.id = a.receipt_id
                  WHERE a.payment_id = p.id AND rc.voided_at IS NULL), 0) AS settled,
         IFNULL((SELECT SUM(ci.amount)
                   FROM ar_charge_items ci
                   JOIN ar_charges ch ON ch.id = ci.charge_id
                  WHERE ci.payment_id = p.id AND ch.voided_at IS NULL), 0) AS charged,
         (SELECT MAX(ci.period_to)
            FROM ar_charge_items ci
            JOIN ar_charges ch ON ch.id = ci.charge_id
           WHERE ci.payment_id = p.id AND ch.voided_at IS NULL) AS interest_through,
         (SELECT bn.note_no
            FROM billing_note_items bi
            JOIN billing_notes bn ON bn.id = bi.billing_note_id
           WHERE bi.payment_id = p.id AND bn.voided_at IS NULL
           LIMIT 1) AS billing_note_no
    FROM payments p
    JOIN orders o ON o.id = p.order_id
   WHERE p.method = 'credit'
`;

/** เรียงเก่าสุดก่อน (ครบกำหนดก่อน → ขายก่อน) — ลำดับเดียวกับที่ใช้ตัดชำระ FIFO */
const OLDEST_FIRST = 'ORDER BY p.due_date, p.created_at, p.id';

const withOutstanding = (row) =>
  row ? { ...row, outstanding: row.amount + row.charged - row.refunded - row.settled } : row;

const RECEIPT_SELECT = `
  SELECT rc.*, c.name AS customer_name, u.name AS received_by_name, v.name AS voided_by_name
    FROM ar_receipts rc
    JOIN customers c ON c.id = rc.customer_id
    LEFT JOIN users u ON u.id = rc.received_by
    LEFT JOIN users v ON v.id = rc.voided_by
`;

const NOTE_SELECT = `
  SELECT bn.*, c.name AS customer_name, u.name AS issued_by_name, v.name AS voided_by_name
    FROM billing_notes bn
    JOIN customers c ON c.id = bn.customer_id
    LEFT JOIN users u ON u.id = bn.issued_by
    LEFT JOIN users v ON v.id = bn.voided_by
`;

export const receivableRepository = {
  invoicesByCustomer(customerId) {
    return getDb()
      .prepare(`${INVOICE_SELECT} AND o.customer_id = ? ${OLDEST_FIRST}`)
      .all(customerId)
      .map(withOutstanding);
  },

  /** บิลขายเชื่อของออเดอร์เดียว — ออเดอร์หนึ่งอาจแยกจ่ายขายเชื่อหลายรอบ (ใช้ตัดสินแต้มสะสม credit-points.js) */
  invoicesByOrder(orderId) {
    return getDb()
      .prepare(`${INVOICE_SELECT} AND p.order_id = ? ${OLDEST_FIRST}`)
      .all(orderId)
      .map(withOutstanding);
  },

  invoiceByPaymentId(paymentId) {
    return withOutstanding(getDb().prepare(`${INVOICE_SELECT} AND p.id = ?`).get(paymentId));
  },

  /** ยอดค้างรวมของลูกค้า (สตางค์) — ใช้เช็ควงเงินตอนขายเชื่อ */
  outstandingByCustomer(customerId) {
    return this.invoicesByCustomer(customerId).reduce(
      (acc, invoice) => acc + Math.max(invoice.outstanding, 0),
      0,
    );
  },

  /** ลูกค้าที่เกี่ยวกับลูกหนี้: มีวงเงินอยู่ หรือยังมีบิลขายเชื่อ (เผื่อถูกลดวงเงินเป็น 0 ทั้งที่ยังค้าง) */
  creditCustomers() {
    return getDb()
      .prepare(
        `
        SELECT DISTINCT c.*
          FROM customers c
          LEFT JOIN orders o ON o.customer_id = c.id
          LEFT JOIN payments p ON p.order_id = o.id AND p.method = 'credit'
         WHERE c.credit_limit > 0 OR p.id IS NOT NULL
         ORDER BY c.name
      `,
      )
      .all();
  },

  todayDate() {
    return getDb().prepare("SELECT date('now') AS d").get().d;
  },

  /** วันที่ในอีก N วัน (YYYY-MM-DD) — คิดด้วย SQLite ให้ตรงกับ date('now') ที่ใช้เทียบวันเกินกำหนด */
  dateAfterDays(days) {
    return getDb()
      .prepare('SELECT date(?, ?) AS d')
      .get('now', `+${Number(days)} days`).d;
  },

  countByPrefix(table, column, prefix) {
    const allowed = [
      'ar_receipts:receipt_no',
      'billing_notes:note_no',
      'ar_charges:charge_no',
      'credit_notes:note_no',
    ];
    if (!allowed.includes(`${table}:${column}`)) {
      throw new Error(`เลขที่เอกสารไม่รองรับ ${table}.${column}`);
    }
    return getDb()
      .prepare(`SELECT COUNT(*) AS c FROM ${table} WHERE ${column} LIKE ?`)
      .get(`${prefix}%`).c;
  },

  // ---------------------------------------------------------------- ใบเสร็จรับชำระหนี้ -----
  createReceipt({ receiptNo, customerId, amount, method, reference, note, shiftId, receivedBy }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO ar_receipts
          (receipt_no, customer_id, amount, method, reference, note, shift_id, received_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `,
      )
      .run(
        receiptNo,
        customerId,
        amount,
        method,
        reference ?? null,
        note ?? null,
        shiftId ?? null,
        receivedBy,
      );
    return this.findReceipt(info.lastInsertRowid);
  },

  addAllocation({ receiptId, paymentId, amount }) {
    getDb()
      .prepare('INSERT INTO ar_allocations (receipt_id, payment_id, amount) VALUES (?, ?, ?)')
      .run(receiptId, paymentId, amount);
  },

  findReceipt(id) {
    return getDb().prepare(`${RECEIPT_SELECT} WHERE rc.id = ?`).get(id);
  },

  receiptsByCustomer(customerId) {
    return getDb()
      .prepare(`${RECEIPT_SELECT} WHERE rc.customer_id = ? ORDER BY rc.id DESC`)
      .all(customerId);
  },

  receiptAllocations(receiptId) {
    return getDb()
      .prepare(
        `
        SELECT a.payment_id, a.amount, p.order_id, o.code AS order_code, p.created_at, p.due_date
          FROM ar_allocations a
          JOIN payments p ON p.id = a.payment_id
          JOIN orders o ON o.id = p.order_id
         WHERE a.receipt_id = ?
         ORDER BY a.id
      `,
      )
      .all(receiptId);
  },

  voidReceipt(id, { reason, voidedBy }) {
    getDb()
      .prepare(
        "UPDATE ar_receipts SET voided_at = datetime('now'), void_reason = ?, voided_by = ? WHERE id = ?",
      )
      .run(reason, voidedBy, id);
    return this.findReceipt(id);
  },

  // ------------------------------------------------------------------------ ใบวางบิล -----
  createNote({ noteNo, customerId, total, dueDate, note, issuedBy }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO billing_notes (note_no, customer_id, total, due_date, note, issued_by)
        VALUES (?, ?, ?, ?, ?, ?)
      `,
      )
      .run(noteNo, customerId, total, dueDate, note ?? null, issuedBy);
    return this.findNote(info.lastInsertRowid);
  },

  addNoteItem({ noteId, paymentId, amount }) {
    getDb()
      .prepare(
        'INSERT INTO billing_note_items (billing_note_id, payment_id, amount) VALUES (?, ?, ?)',
      )
      .run(noteId, paymentId, amount);
  },

  findNote(id) {
    return getDb().prepare(`${NOTE_SELECT} WHERE bn.id = ?`).get(id);
  },

  notesByCustomer(customerId) {
    return getDb()
      .prepare(`${NOTE_SELECT} WHERE bn.customer_id = ? ORDER BY bn.id DESC`)
      .all(customerId);
  },

  noteItems(noteId) {
    return getDb()
      .prepare(
        `
        SELECT bi.payment_id, bi.amount, o.code AS order_code, p.created_at, p.due_date
          FROM billing_note_items bi
          JOIN payments p ON p.id = bi.payment_id
          JOIN orders o ON o.id = p.order_id
         WHERE bi.billing_note_id = ?
         ORDER BY p.due_date, p.created_at, p.id
      `,
      )
      .all(noteId);
  },

  voidNote(id, { reason, voidedBy }) {
    getDb()
      .prepare(
        "UPDATE billing_notes SET voided_at = datetime('now'), void_reason = ?, voided_by = ? WHERE id = ?",
      )
      .run(reason, voidedBy, id);
    return this.findNote(id);
  },

  /** เงินสดรับชำระหนี้ระหว่างกะ (ไม่นับใบที่ยกเลิก) — เข้าลิ้นชักเหมือนรับค่าอาหารเป็นเงินสด */
  cashReceivedDuring(shiftId) {
    return getDb()
      .prepare(
        `SELECT IFNULL(SUM(amount), 0) AS total
           FROM ar_receipts
          WHERE shift_id = ? AND method = 'cash' AND voided_at IS NULL`,
      )
      .get(shiftId).total;
  },

  /** สรุปรับชำระหนี้ของกะแยกตามช่องทาง — ใช้ใน Z-report */
  byShiftMethod(shiftId) {
    return getDb()
      .prepare(
        `SELECT method, COUNT(*) AS count, IFNULL(SUM(amount), 0) AS amount
           FROM ar_receipts
          WHERE shift_id = ? AND voided_at IS NULL
          GROUP BY method
          ORDER BY method`,
      )
      .all(shiftId);
  },
};

export default receivableRepository;
