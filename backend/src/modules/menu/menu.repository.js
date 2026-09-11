import { getDb } from '../../db/index.js';

export const menuRepository = {
  findAll({ categoryId, search, availableOnly, recommendedOnly, page = 1, limit = 100 } = {}) {
    const clauses = [];
    const params = [];

    if (categoryId) {
      clauses.push('m.category_id = ?');
      params.push(categoryId);
    }
    if (search) {
      clauses.push("(m.name LIKE ? OR IFNULL(m.name_en, '') LIKE ?)");
      params.push(`%${search}%`, `%${search}%`);
    }
    if (availableOnly) clauses.push('m.is_available = 1');
    if (recommendedOnly) clauses.push('m.is_recommended = 1');

    const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
    const db = getDb();
    const total = db.prepare(`SELECT COUNT(*) AS c FROM menu_items m ${where}`).get(...params).c;
    const offset = (page - 1) * limit;

    const items = db
      .prepare(
        `
        SELECT m.*, c.name AS category_name
          FROM menu_items m
          JOIN categories c ON c.id = m.category_id
          ${where}
         ORDER BY m.sort_order, m.id
         LIMIT ? OFFSET ?
      `,
      )
      .all(...params, limit, offset);

    return { items, total };
  },

  findById(id) {
    return getDb()
      .prepare(
        `
        SELECT m.*, c.name AS category_name
          FROM menu_items m
          JOIN categories c ON c.id = m.category_id
         WHERE m.id = ?
      `,
      )
      .get(id);
  },

  findOptionGroups(menuItemId) {
    const db = getDb();
    const groups = db
      .prepare('SELECT * FROM option_groups WHERE menu_item_id = ? ORDER BY sort_order, id')
      .all(menuItemId);
    if (groups.length === 0) return [];

    const options = db
      .prepare(
        `
        SELECT o.* FROM options o
          JOIN option_groups g ON g.id = o.group_id
         WHERE g.menu_item_id = ?
         ORDER BY o.sort_order, o.id
      `,
      )
      .all(menuItemId);

    return groups.map((group) => ({
      ...group,
      options: options.filter((option) => option.group_id === group.id),
    }));
  },

  /** ดึงกลุ่มตัวเลือกของหลายเมนูพร้อมกัน เพื่อเลี่ยงปัญหา N+1 ตอน list */
  findOptionGroupsForItems(menuItemIds) {
    if (menuItemIds.length === 0) return new Map();
    const placeholders = menuItemIds.map(() => '?').join(',');
    const db = getDb();

    const groups = db
      .prepare(
        `SELECT * FROM option_groups WHERE menu_item_id IN (${placeholders}) ORDER BY sort_order, id`,
      )
      .all(...menuItemIds);
    const options = db
      .prepare(
        `
        SELECT o.* FROM options o
          JOIN option_groups g ON g.id = o.group_id
         WHERE g.menu_item_id IN (${placeholders})
         ORDER BY o.sort_order, o.id
      `,
      )
      .all(...menuItemIds);

    const grouped = new Map();
    for (const group of groups) {
      const withOptions = { ...group, options: options.filter((o) => o.group_id === group.id) };
      const list = grouped.get(group.menu_item_id) ?? [];
      list.push(withOptions);
      grouped.set(group.menu_item_id, list);
    }
    return grouped;
  },

  findOptionById(optionId) {
    return getDb()
      .prepare(
        `
        SELECT o.*, g.menu_item_id, g.name AS group_name
          FROM options o
          JOIN option_groups g ON g.id = o.group_id
         WHERE o.id = ?
      `,
      )
      .get(optionId);
  },

  create(payload) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO menu_items
          (category_id, name, name_en, description, price, image_url, is_available, is_recommended, prep_minutes, sort_order)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      )
      .run(
        payload.categoryId,
        payload.name,
        payload.nameEn ?? null,
        payload.description ?? null,
        payload.price,
        payload.imageUrl ?? null,
        payload.isAvailable === false ? 0 : 1,
        payload.isRecommended ? 1 : 0,
        payload.prepMinutes ?? 10,
        payload.sortOrder ?? 0,
      );
    return this.findById(info.lastInsertRowid);
  },

  update(id, payload) {
    getDb()
      .prepare(
        `
        UPDATE menu_items
           SET category_id           = COALESCE(?, category_id),
               name                  = COALESCE(?, name),
               name_en               = COALESCE(?, name_en),
               description           = COALESCE(?, description),
               price                 = COALESCE(?, price),
               image_url             = COALESCE(?, image_url),
               is_available          = COALESCE(?, is_available),
               is_recommended        = COALESCE(?, is_recommended),
               prep_minutes          = COALESCE(?, prep_minutes),
               sort_order            = COALESCE(?, sort_order),
               auto_disabled_by_stock = COALESCE(?, auto_disabled_by_stock),
               updated_at            = datetime('now')
         WHERE id = ?
      `,
      )
      .run(
        payload.categoryId ?? null,
        payload.name ?? null,
        payload.nameEn ?? null,
        payload.description ?? null,
        payload.price ?? null,
        payload.imageUrl ?? null,
        payload.isAvailable === undefined ? null : Number(payload.isAvailable),
        payload.isRecommended === undefined ? null : Number(payload.isRecommended),
        payload.prepMinutes ?? null,
        payload.sortOrder ?? null,
        payload.autoDisabledByStock === undefined ? null : Number(payload.autoDisabledByStock),
        id,
      );
    return this.findById(id);
  },

  /** เปิด/ปิดขายเมนูจากระบบสต๊อกโดยตรง — ตั้งทั้ง is_available และ auto_disabled_by_stock
   * เสมอ (ไม่ใช้ COALESCE) เพื่อแยกจากการแก้ไขมือผ่าน update()/setAvailability ปกติ */
  setStockAvailability(id, isAvailable, autoDisabledByStock) {
    getDb()
      .prepare(
        `
        UPDATE menu_items
           SET is_available           = ?,
               auto_disabled_by_stock = ?,
               updated_at             = datetime('now')
         WHERE id = ?
      `,
      )
      .run(isAvailable ? 1 : 0, autoDisabledByStock ? 1 : 0, id);
    return this.findById(id);
  },

  remove(id) {
    return getDb().prepare('DELETE FROM menu_items WHERE id = ?').run(id).changes > 0;
  },

  findIngredientLinks(menuItemId) {
    return getDb()
      .prepare(
        `
        SELECT mii.*, i.name AS ingredient_name, i.unit AS ingredient_unit
          FROM menu_item_ingredients mii
          JOIN ingredients i ON i.id = mii.ingredient_id
         WHERE mii.menu_item_id = ?
         ORDER BY mii.id
      `,
      )
      .all(menuItemId);
  },

  /** ดึงวัตถุดิบที่ผูกไว้ของหลายเมนูพร้อมกัน เพื่อเลี่ยงปัญหา N+1 ตอน list */
  findIngredientLinksForItems(menuItemIds) {
    if (menuItemIds.length === 0) return new Map();
    const placeholders = menuItemIds.map(() => '?').join(',');
    const rows = getDb()
      .prepare(
        `
        SELECT mii.*, i.name AS ingredient_name, i.unit AS ingredient_unit
          FROM menu_item_ingredients mii
          JOIN ingredients i ON i.id = mii.ingredient_id
         WHERE mii.menu_item_id IN (${placeholders})
         ORDER BY mii.id
      `,
      )
      .all(...menuItemIds);

    const grouped = new Map();
    for (const row of rows) {
      const list = grouped.get(row.menu_item_id) ?? [];
      list.push(row);
      grouped.set(row.menu_item_id, list);
    }
    return grouped;
  },

  removeIngredientLinks(menuItemId) {
    getDb().prepare('DELETE FROM menu_item_ingredients WHERE menu_item_id = ?').run(menuItemId);
  },

  createIngredientLink(menuItemId, { ingredientId, qtyPerUnit }) {
    getDb()
      .prepare(
        'INSERT INTO menu_item_ingredients (menu_item_id, ingredient_id, qty_per_unit) VALUES (?, ?, ?)',
      )
      .run(menuItemId, ingredientId, qtyPerUnit);
  },

  createOptionGroup(menuItemId, { name, minSelect, maxSelect, isRequired, sortOrder }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO option_groups (menu_item_id, name, min_select, max_select, is_required, sort_order)
        VALUES (?, ?, ?, ?, ?, ?)
      `,
      )
      .run(menuItemId, name, minSelect ?? 0, maxSelect ?? 1, isRequired ? 1 : 0, sortOrder ?? 0);
    return info.lastInsertRowid;
  },

  createOption(groupId, { name, priceDelta, isDefault, sortOrder }) {
    return getDb()
      .prepare(
        'INSERT INTO options (group_id, name, price_delta, is_default, sort_order) VALUES (?, ?, ?, ?, ?)',
      )
      .run(groupId, name, priceDelta ?? 0, isDefault ? 1 : 0, sortOrder ?? 0).lastInsertRowid;
  },

  removeOptionGroups(menuItemId) {
    getDb().prepare('DELETE FROM option_groups WHERE menu_item_id = ?').run(menuItemId);
  },
};

export default menuRepository;
