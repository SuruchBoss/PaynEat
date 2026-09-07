import { getDb } from '../../db/index.js';

export const tableRepository = {
  findAll({ zone, status, activeOnly = true } = {}) {
    const clauses = [];
    const params = [];
    if (activeOnly) clauses.push('t.is_active = 1');
    if (zone) {
      clauses.push('t.zone = ?');
      params.push(zone);
    }
    if (status) {
      clauses.push('t.status = ?');
      params.push(status);
    }
    const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';

    // ผูกออเดอร์ที่ยังเปิดอยู่ของแต่ละโต๊ะมาด้วย เพื่อให้หน้าผังโต๊ะแสดงยอดได้ทันที
    return getDb()
      .prepare(
        `
        SELECT t.*,
               o.id         AS order_id,
               o.code       AS order_code,
               o.total      AS order_total,
               o.status     AS order_status,
               o.guest_count AS order_guest_count,
               o.created_at AS order_created_at
          FROM dining_tables t
          LEFT JOIN orders o
                 ON o.table_id = t.id
                AND o.status IN ('open', 'in_kitchen', 'served')
          ${where}
         ORDER BY t.zone, t.name
      `,
      )
      .all(...params);
  },

  findById(id) {
    return getDb().prepare('SELECT * FROM dining_tables WHERE id = ?').get(id);
  },

  findByName(name) {
    return getDb().prepare('SELECT * FROM dining_tables WHERE name = ?').get(name);
  },

  zones() {
    return getDb()
      .prepare('SELECT DISTINCT zone FROM dining_tables WHERE is_active = 1 ORDER BY zone')
      .all()
      .map((row) => row.zone);
  },

  create({ name, zone, seats }) {
    const info = getDb()
      .prepare('INSERT INTO dining_tables (name, zone, seats) VALUES (?, ?, ?)')
      .run(name, zone ?? 'main', seats ?? 4);
    return this.findById(info.lastInsertRowid);
  },

  update(id, { name, zone, seats, status, isActive }) {
    getDb()
      .prepare(
        `
        UPDATE dining_tables
           SET name       = COALESCE(?, name),
               zone       = COALESCE(?, zone),
               seats      = COALESCE(?, seats),
               status     = COALESCE(?, status),
               is_active  = COALESCE(?, is_active),
               updated_at = datetime('now')
         WHERE id = ?
      `,
      )
      .run(
        name ?? null,
        zone ?? null,
        seats ?? null,
        status ?? null,
        isActive === undefined ? null : Number(isActive),
        id,
      );
    return this.findById(id);
  },

  setStatus(id, status) {
    getDb()
      .prepare("UPDATE dining_tables SET status = ?, updated_at = datetime('now') WHERE id = ?")
      .run(status, id);
    return this.findById(id);
  },

  hasOpenOrder(id) {
    return (
      getDb()
        .prepare(
          `
          SELECT COUNT(*) AS c FROM orders
           WHERE table_id = ? AND status IN ('open', 'in_kitchen', 'served')
        `,
        )
        .get(id).c > 0
    );
  },

  remove(id) {
    return getDb().prepare('DELETE FROM dining_tables WHERE id = ?').run(id).changes > 0;
  },
};

export default tableRepository;
