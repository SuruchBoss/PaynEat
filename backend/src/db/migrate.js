import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { getDb } from './index.js';
import { env } from '../config/env.js';

const here = path.dirname(fileURLToPath(import.meta.url));

/**
 * เพิ่มคอลัมน์ให้ตารางที่มีอยู่แล้ว (schema.sql ใช้ CREATE TABLE IF NOT EXISTS
 * จึงไม่แก้ตารางเดิมที่มีอยู่แล้วให้อัตโนมัติ) — เรียกซ้ำได้ปลอดภัยเพราะเช็คก่อนว่ามีคอลัมน์อยู่แล้วหรือยัง
 * ต้องเรียก *หลัง* `db.exec(sql)` เสมอ เพราะบางคอลัมน์ (เช่น auto_disabled_by_stock) ไม่ได้อยู่ใน
 * CREATE TABLE ของ schema.sql เลย ตั้งใจพึ่ง ALTER TABLE นี้อย่างเดียวเพื่อให้ตารางถูกสร้างขึ้นก่อน
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
  addColumnIfMissing(
    db,
    'payments',
    'shift_id',
    'INTEGER REFERENCES shifts(id) ON DELETE SET NULL',
  );
  addColumnIfMissing(
    db,
    'orders',
    'promotion_id',
    'INTEGER REFERENCES promotions(id) ON DELETE SET NULL',
  );
  addColumnIfMissing(db, 'orders', 'promotion_name_snapshot', 'TEXT');
  addColumnIfMissing(db, 'orders', 'promotion_code_snapshot', 'TEXT');
  addColumnIfMissing(db, 'orders', 'promotion_discount_amount', 'INTEGER NOT NULL DEFAULT 0');
  addColumnIfMissing(db, 'order_items', 'stock_deducted', 'INTEGER NOT NULL DEFAULT 0');
  addColumnIfMissing(db, 'menu_items', 'auto_disabled_by_stock', 'INTEGER NOT NULL DEFAULT 0');
  // ticket 09 (ลูกค้า/แต้มสะสม) ลืมเพิ่มรายการเหล่านี้ไว้ตอนนั้น — เติมให้ครบตอนนี้เพื่อไม่ให้
  // ฐานข้อมูลที่มีอยู่แล้วตั้งแต่ก่อนทิกเก็ต 09 พังตอนอัปเกรด (คอลัมน์เหล่านี้อยู่ใน schema.sql
  // อยู่แล้วสำหรับฐานข้อมูลใหม่ แต่ CREATE TABLE IF NOT EXISTS ไม่แก้ตารางเดิมที่มีอยู่แล้ว)
  addColumnIfMissing(
    db,
    'orders',
    'customer_id',
    'INTEGER REFERENCES customers(id) ON DELETE SET NULL',
  );
  addColumnIfMissing(db, 'orders', 'points_earned', 'INTEGER NOT NULL DEFAULT 0');
  addColumnIfMissing(db, 'payments', 'points_redeemed', 'INTEGER NOT NULL DEFAULT 0');
  addColumnIfMissing(db, 'payments', 'points_redeemed_value', 'INTEGER NOT NULL DEFAULT 0');
  addColumnIfMissing(db, 'orders', 'queue_number', 'INTEGER');

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
