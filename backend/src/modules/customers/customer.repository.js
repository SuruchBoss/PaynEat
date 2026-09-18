import { getDb } from '../../db/index.js';

export const customerRepository = {
  findById(id) {
    return getDb().prepare('SELECT * FROM customers WHERE id = ?').get(id);
  },

  findByPhone(phone) {
    return getDb().prepare('SELECT * FROM customers WHERE phone = ?').get(phone);
  },

  findAll({ search, page = 1, limit = 20 } = {}) {
    const where = search ? 'WHERE phone LIKE ? OR name LIKE ?' : '';
    const params = search ? [`%${search}%`, `%${search}%`] : [];

    const db = getDb();
    const total = db.prepare(`SELECT COUNT(*) AS c FROM customers ${where}`).get(...params).c;
    const rows = db
      .prepare(`SELECT * FROM customers ${where} ORDER BY name LIMIT ? OFFSET ?`)
      .all(...params, limit, (page - 1) * limit);

    return { rows, total };
  },

  create({ name, phone, email }) {
    const info = getDb()
      .prepare('INSERT INTO customers (name, phone, email) VALUES (?, ?, ?)')
      .run(name, phone, email ?? null);
    return this.findById(info.lastInsertRowid);
  },

  /** ลูกค้าที่สั่งบ่อยสุดในช่วงเวลาที่กำหนด (นับเฉพาะออเดอร์จ่ายแล้ว) — ดู
   * docs/tickets/15-ai-ask-your-data.md ใช้ตอบคำถามประเภท "ลูกค้าคนไหนซื้อบ่อยสุด" */
  topByOrders({ from, to, limit = 10 } = {}) {
    const start = from ?? '1970-01-01';
    const end = to ?? '2999-12-31';
    return getDb()
      .prepare(
        `
        SELECT c.id, c.name, c.phone,
               COUNT(o.id)            AS order_count,
               IFNULL(SUM(o.total), 0) AS total_spent
          FROM customers c
          JOIN orders o ON o.customer_id = c.id
         WHERE o.status = 'paid'
           AND date(o.created_at) BETWEEN date(?) AND date(?)
         GROUP BY c.id
         ORDER BY order_count DESC, total_spent DESC
         LIMIT ?
      `,
      )
      .all(start, end, limit);
  },

  /** บวก/ลบแต้มสะสม (delta ติดลบ = ใช้แต้ม, บวก = สะสมแต้ม) — ทางเดียวที่แก้ points_balance ได้ */
  adjustPoints(id, delta) {
    getDb()
      .prepare(
        `
        UPDATE customers
           SET points_balance = points_balance + ?,
               updated_at     = datetime('now')
         WHERE id = ?
      `,
      )
      .run(delta, id);
    return this.findById(id);
  },
};

export default customerRepository;
