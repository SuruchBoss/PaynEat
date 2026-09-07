import { getDb } from '../../db/index.js';

export const categoryRepository = {
  findAll({ activeOnly = false } = {}) {
    const where = activeOnly ? 'WHERE is_active = 1' : '';
    return getDb()
      .prepare(
        `
        SELECT c.*, (
          SELECT COUNT(*) FROM menu_items m WHERE m.category_id = c.id
        ) AS item_count
        FROM categories c ${where}
        ORDER BY c.sort_order, c.id
      `,
      )
      .all();
  },

  findById(id) {
    return getDb().prepare('SELECT * FROM categories WHERE id = ?').get(id);
  },

  create({ name, nameEn, icon, sortOrder }) {
    const info = getDb()
      .prepare('INSERT INTO categories (name, name_en, icon, sort_order) VALUES (?, ?, ?, ?)')
      .run(name, nameEn ?? null, icon ?? null, sortOrder ?? 0);
    return this.findById(info.lastInsertRowid);
  },

  update(id, { name, nameEn, icon, sortOrder, isActive }) {
    getDb()
      .prepare(
        `
        UPDATE categories
           SET name       = COALESCE(?, name),
               name_en    = COALESCE(?, name_en),
               icon       = COALESCE(?, icon),
               sort_order = COALESCE(?, sort_order),
               is_active  = COALESCE(?, is_active),
               updated_at = datetime('now')
         WHERE id = ?
      `,
      )
      .run(
        name ?? null,
        nameEn ?? null,
        icon ?? null,
        sortOrder ?? null,
        isActive === undefined ? null : Number(isActive),
        id,
      );
    return this.findById(id);
  },

  countItems(id) {
    return getDb().prepare('SELECT COUNT(*) AS c FROM menu_items WHERE category_id = ?').get(id).c;
  },

  remove(id) {
    return getDb().prepare('DELETE FROM categories WHERE id = ?').run(id).changes > 0;
  },
};

export default categoryRepository;
