import { getDb } from '../../db/index.js';

export const ingredientRepository = {
  findAll({ lowStockOnly } = {}) {
    const where = lowStockOnly ? 'WHERE current_stock <= low_stock_threshold' : '';
    return getDb().prepare(`SELECT * FROM ingredients ${where} ORDER BY name`).all();
  },

  findById(id) {
    return getDb().prepare('SELECT * FROM ingredients WHERE id = ?').get(id);
  },

  findByIds(ids) {
    if (ids.length === 0) return [];
    const placeholders = ids.map(() => '?').join(',');
    return getDb()
      .prepare(`SELECT * FROM ingredients WHERE id IN (${placeholders})`)
      .all(...ids);
  },

  /** เมนูทั้งหมดที่ผูกกับวัตถุดิบนี้ — ใช้ตอน sync สถานะเปิด/ปิดขายเมนูเมื่อสต๊อกเปลี่ยน */
  findMenuItemLinksForIngredient(ingredientId) {
    return getDb()
      .prepare('SELECT * FROM menu_item_ingredients WHERE ingredient_id = ?')
      .all(ingredientId);
  },

  countMenuItemLinks(ingredientId) {
    return getDb()
      .prepare('SELECT COUNT(*) AS c FROM menu_item_ingredients WHERE ingredient_id = ?')
      .get(ingredientId).c;
  },

  create({ name, unit, currentStock, lowStockThreshold }) {
    const info = getDb()
      .prepare(
        'INSERT INTO ingredients (name, unit, current_stock, low_stock_threshold) VALUES (?, ?, ?, ?)',
      )
      .run(name, unit, currentStock ?? 0, lowStockThreshold ?? 0);
    return this.findById(info.lastInsertRowid);
  },

  update(id, { name, unit, lowStockThreshold }) {
    getDb()
      .prepare(
        `
        UPDATE ingredients
           SET name                = COALESCE(?, name),
               unit                = COALESCE(?, unit),
               low_stock_threshold = COALESCE(?, low_stock_threshold),
               updated_at          = datetime('now')
         WHERE id = ?
      `,
      )
      .run(name ?? null, unit ?? null, lowStockThreshold ?? null, id);
    return this.findById(id);
  },

  /** บวก/ลบสต๊อก (delta ติดลบ = หัก, บวก = เติม) — ทางเดียวที่แก้ current_stock ได้ */
  adjustStock(id, delta) {
    getDb()
      .prepare(
        `
        UPDATE ingredients
           SET current_stock = current_stock + ?,
               updated_at    = datetime('now')
         WHERE id = ?
      `,
      )
      .run(delta, id);
    return this.findById(id);
  },

  remove(id) {
    return getDb().prepare('DELETE FROM ingredients WHERE id = ?').run(id).changes > 0;
  },
};

export default ingredientRepository;
