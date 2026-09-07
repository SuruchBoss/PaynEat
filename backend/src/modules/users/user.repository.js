import { getDb } from '../../db/index.js';

const BASE_COLUMNS = 'id, name, username, role, is_active, created_at, updated_at';

export const userRepository = {
  findAll({ role, isActive } = {}) {
    const clauses = [];
    const params = [];
    if (role) {
      clauses.push('role = ?');
      params.push(role);
    }
    if (isActive !== undefined) {
      clauses.push('is_active = ?');
      params.push(isActive ? 1 : 0);
    }
    const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
    return getDb()
      .prepare(`SELECT ${BASE_COLUMNS} FROM users ${where} ORDER BY role, name`)
      .all(...params);
  },

  findById(id) {
    return getDb().prepare(`SELECT ${BASE_COLUMNS} FROM users WHERE id = ?`).get(id);
  },

  findByUsername(username) {
    return getDb().prepare('SELECT * FROM users WHERE username = ?').get(username);
  },

  create({ name, username, passwordHash, role }) {
    const info = getDb()
      .prepare('INSERT INTO users (name, username, password_hash, role) VALUES (?, ?, ?, ?)')
      .run(name, username, passwordHash, role);
    return this.findById(info.lastInsertRowid);
  },

  update(id, { name, role, isActive }) {
    getDb()
      .prepare(
        `
        UPDATE users
           SET name       = COALESCE(?, name),
               role       = COALESCE(?, role),
               is_active  = COALESCE(?, is_active),
               updated_at = datetime('now')
         WHERE id = ?
      `,
      )
      .run(name ?? null, role ?? null, isActive === undefined ? null : Number(isActive), id);
    return this.findById(id);
  },

  updatePassword(id, passwordHash) {
    getDb()
      .prepare("UPDATE users SET password_hash = ?, updated_at = datetime('now') WHERE id = ?")
      .run(passwordHash, id);
    return this.findById(id);
  },

  remove(id) {
    return getDb().prepare('DELETE FROM users WHERE id = ?').run(id).changes > 0;
  },
};

export default userRepository;
