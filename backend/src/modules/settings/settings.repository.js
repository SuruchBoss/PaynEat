import { getDb } from '../../db/index.js';

export const settingsRepository = {
  all() {
    return getDb().prepare('SELECT key, value FROM settings').all();
  },

  get(key) {
    return getDb().prepare('SELECT value FROM settings WHERE key = ?').get(key)?.value;
  },

  set(key, value) {
    getDb()
      .prepare(
        `
        INSERT INTO settings (key, value) VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = datetime('now')
      `,
      )
      .run(key, String(value));
  },
};

export default settingsRepository;
