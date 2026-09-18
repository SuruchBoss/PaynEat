import { getDb } from '../../db/index.js';

export const branchRepository = {
  findAll({ activeOnly } = {}) {
    const where = activeOnly ? 'WHERE is_active = 1' : '';
    return getDb().prepare(`SELECT * FROM branches ${where} ORDER BY name`).all();
  },

  findById(id) {
    return getDb().prepare('SELECT * FROM branches WHERE id = ?').get(id);
  },

  /** สาขาที่ user คนนี้เข้าถึงได้ — admin เห็นทุกสาขาที่ยัง active เสมอโดยไม่ต้องมีแถวใน
   * user_branches เลย (ดู docs/DECISIONS.md #36) เรียง ORDER BY id (ไม่ใช่ name) เพื่อให้ตอน login
   * แล้ว auto-select สาขาแรกให้ admin เสมอได้สาขาที่สร้างก่อน (สาขาเดิมก่อนทิกเก็ตนี้) ไม่ใช่สาขาที่
   * ชื่อมาก่อนตามตัวอักษรซึ่งไม่เกี่ยวกับลำดับความสำคัญเลย */
  listForUser(user) {
    if (user.role === 'admin') {
      return getDb()
        .prepare('SELECT * FROM branches WHERE is_active = 1 ORDER BY id')
        .all();
    }
    return getDb()
      .prepare(
        `
        SELECT b.* FROM branches b
        JOIN user_branches ub ON ub.branch_id = b.id
         AND ub.user_id = ?
        WHERE b.is_active = 1
        ORDER BY b.name
      `,
      )
      .all(user.id);
  },

  /** admin ผ่านเสมอ (bypass) — คนอื่นต้องมีแถวใน user_branches กับสาขานั้นที่ยัง active อยู่
   * เรียกทุก request ที่มี branchId (ดู middlewares/auth.js#attachBranch) ไม่ใช่เชื่อแค่ตอน login
   * เพื่อให้ถอดสิทธิ์สาขาออกมีผลทันที เหมือนหลักการเดียวกับ is_active/role ของ user เอง */
  hasAccess(user, branchId) {
    if (user.role === 'admin') return true;
    return Boolean(
      getDb()
        .prepare(
          `
          SELECT 1 FROM user_branches ub
          JOIN branches b ON b.id = ub.branch_id
          WHERE ub.user_id = ? AND ub.branch_id = ? AND b.is_active = 1
        `,
        )
        .get(user.id, branchId),
    );
  },

  create({ name, code, address }) {
    const info = getDb()
      .prepare('INSERT INTO branches (name, code, address) VALUES (?, ?, ?)')
      .run(name, code ?? null, address ?? null);
    return this.findById(info.lastInsertRowid);
  },

  update(id, { name, code, address, isActive }) {
    getDb()
      .prepare(
        `
        UPDATE branches
           SET name       = COALESCE(?, name),
               code       = COALESCE(?, code),
               address    = COALESCE(?, address),
               is_active  = COALESCE(?, is_active),
               updated_at = datetime('now')
         WHERE id = ?
      `,
      )
      .run(
        name ?? null,
        code ?? null,
        address ?? null,
        isActive === undefined ? null : Number(isActive),
        id,
      );
    return this.findById(id);
  },

  addUser(userId, branchId) {
    getDb()
      .prepare('INSERT OR IGNORE INTO user_branches (user_id, branch_id) VALUES (?, ?)')
      .run(userId, branchId);
  },

  removeUser(userId, branchId) {
    getDb()
      .prepare('DELETE FROM user_branches WHERE user_id = ? AND branch_id = ?')
      .run(userId, branchId);
  },
};

export default branchRepository;
