import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { getDb } from './index.js';
import { env } from '../config/env.js';

const here = path.dirname(fileURLToPath(import.meta.url));

/**
 * เพิ่มคอลัมน์ให้ตารางที่มีอยู่แล้ว (schema.sql ใช้ CREATE TABLE IF NOT EXISTS
 * จึงไม่แก้ตารางเดิมที่มีอยู่แล้วให้อัตโนมัติ) — เรียกซ้ำได้ปลอดภัยเพราะเช็คก่อนว่ามีคอลัมน์อยู่แล้วหรือยัง
 */
const addColumnIfMissing = (db, table, column, definition) => {
  const columns = db.prepare(`PRAGMA table_info(${table})`).all();
  if (columns.some((row) => row.name === column)) return;
  db.exec(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`);
};

export const migrate = () => {
  const db = getDb();
  const sql = fs.readFileSync(path.join(here, 'schema.sql'), 'utf8');
  db.exec(sql);

  addColumnIfMissing(db, 'order_items', 'is_paid', 'INTEGER NOT NULL DEFAULT 0');

  const defaults = {
    store_name: env.store.name,
    currency: env.store.currency,
    vat_rate: String(env.store.vatRate),
    service_charge_rate: String(env.store.serviceChargeRate),
    vat_included: String(env.store.vatIncluded),
  };
  const upsert = db.prepare(
    'INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO NOTHING',
  );
  for (const [key, value] of Object.entries(defaults)) upsert.run(key, value);

  return db;
};

if (import.meta.url === `file://${process.argv[1]}`) {
  migrate();
  console.log(`✅ migrate เสร็จแล้ว → ${env.databaseFile}`);
}

export default migrate;
