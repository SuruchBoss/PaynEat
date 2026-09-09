import { getDb } from '../../db/index.js';

const withNames = `
  SELECT s.*, o.name AS opened_by_name, c.name AS closed_by_name
    FROM shifts s
    LEFT JOIN users o ON o.id = s.opened_by
    LEFT JOIN users c ON c.id = s.closed_by
`;

export const shiftRepository = {
  findOpen() {
    return getDb().prepare(`${withNames} WHERE s.status = 'open' ORDER BY s.id DESC LIMIT 1`).get();
  },

  findById(id) {
    return getDb().prepare(`${withNames} WHERE s.id = ?`).get(id);
  },

  list({ limit = 30 } = {}) {
    return getDb().prepare(`${withNames} ORDER BY s.id DESC LIMIT ?`).all(limit);
  },

  open({ openedBy, openingCash }) {
    const info = getDb()
      .prepare('INSERT INTO shifts (opened_by, opening_cash) VALUES (?, ?)')
      .run(openedBy, openingCash);
    return this.findById(info.lastInsertRowid);
  },

  /** ยอดเงินสดที่รับเข้าระหว่างกะนี้ (ไม่รวมช่องทางอื่น) ใช้คำนวณยอดคาดหวังตอนปิดกะ */
  cashInDuring(shiftId) {
    return getDb()
      .prepare(
        `SELECT IFNULL(SUM(amount), 0) AS total FROM payments WHERE shift_id = ? AND method = 'cash'`,
      )
      .get(shiftId).total;
  },

  close(id, { closedBy, expectedCash, countedCash, variance, note }) {
    getDb()
      .prepare(
        `
        UPDATE shifts
           SET status        = 'closed',
               closed_by     = ?,
               closed_at     = datetime('now'),
               expected_cash = ?,
               counted_cash  = ?,
               variance      = ?,
               note          = ?
         WHERE id = ?
      `,
      )
      .run(closedBy, expectedCash, countedCash, variance, note ?? null, id);
    return this.findById(id);
  },
};

export default shiftRepository;
