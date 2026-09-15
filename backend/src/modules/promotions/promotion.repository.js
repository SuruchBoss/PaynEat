import { getDb } from '../../db/index.js';

export const promotionRepository = {
  findAll({ activeOnly = false } = {}) {
    const where = activeOnly ? 'WHERE is_active = 1' : '';
    return getDb()
      .prepare(`SELECT * FROM promotions ${where} ORDER BY created_at DESC, id DESC`)
      .all();
  },

  /** โปรโมชันที่เปิดใช้งานทั้งหมด — ให้ promotion.engine.js กรองเงื่อนไขวันที่/เวลาเองอีกที */
  findActiveForEngine() {
    return getDb().prepare('SELECT * FROM promotions WHERE is_active = 1').all();
  },

  findById(id) {
    return getDb().prepare('SELECT * FROM promotions WHERE id = ?').get(id);
  },

  findByCode(code) {
    return getDb().prepare('SELECT * FROM promotions WHERE code = ? COLLATE NOCASE').get(code);
  },

  create({ name, type, value, code, conditionsJson, isActive, validFrom, validTo }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO promotions (name, type, value, code, conditions_json, is_active, valid_from, valid_to)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `,
      )
      .run(
        name,
        type,
        value,
        code ?? null,
        conditionsJson,
        isActive === false ? 0 : 1,
        validFrom ?? null,
        validTo ?? null,
      );
    return this.findById(info.lastInsertRowid);
  },

  update(id, { name, type, value, code, conditionsJson, isActive, validFrom, validTo }) {
    const existing = this.findById(id);
    getDb()
      .prepare(
        `
        UPDATE promotions
           SET name            = COALESCE(?, name),
               type            = COALESCE(?, type),
               value           = COALESCE(?, value),
               code            = ?,
               conditions_json = COALESCE(?, conditions_json),
               is_active       = COALESCE(?, is_active),
               valid_from      = ?,
               valid_to        = ?,
               updated_at      = datetime('now')
         WHERE id = ?
      `,
      )
      .run(
        name ?? null,
        type ?? null,
        value === undefined ? null : value,
        code === undefined ? (existing?.code ?? null) : code,
        conditionsJson ?? null,
        isActive === undefined ? null : Number(isActive),
        validFrom === undefined ? (existing?.valid_from ?? null) : validFrom,
        validTo === undefined ? (existing?.valid_to ?? null) : validTo,
        id,
      );
    return this.findById(id);
  },

  remove(id) {
    return getDb().prepare('DELETE FROM promotions WHERE id = ?').run(id).changes > 0;
  },
};

export default promotionRepository;
