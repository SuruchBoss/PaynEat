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

const BRANCH_SCOPED_TABLES = ['dining_tables', 'menu_items', 'orders', 'ingredients'];

/**
 * รองรับฐานข้อมูลเดี่ยวสาขาเดิม (ก่อน ticket 11) ที่เพิ่งได้คอลัมน์ branch_id ใหม่จาก
 * addColumnIfMissing ด้านบน — ทุกแถวเดิมจะเป็น branch_id = NULL ต้องมีสาขาให้ข้อมูลเดิมอยู่ ไม่งั้น
 * query ที่ scope ด้วย branch_id จะมองไม่เห็นข้อมูลเดิมเลย จึงสร้างสาขา fallback ("สาขาหลัก") ให้
 * อัตโนมัติเฉพาะตอนพบข้อมูลเก่าที่ยัง branch_id เป็น NULL อยู่จริงเท่านั้น (ดู docs/DECISIONS.md #36)
 * — ฐานข้อมูลใหม่ล้วน (ตารางทั้ง 4 ยังว่างเปล่า) จะไม่สร้างสาขานี้ขึ้นมาเลย ปล่อยให้ seed.js
 * เป็นคนสร้างสาขาจริงเอง 2 สาขาแทน
 */
const backfillDefaultBranch = (db) => {
  const hasUnscopedRows = BRANCH_SCOPED_TABLES.some(
    (table) => db.prepare(`SELECT 1 FROM ${table} WHERE branch_id IS NULL LIMIT 1`).get(),
  );
  if (!hasUnscopedRows) return;

  let defaultBranch = db.prepare('SELECT id FROM branches ORDER BY id LIMIT 1').get();
  if (!defaultBranch) {
    const info = db
      .prepare('INSERT INTO branches (name, code) VALUES (?, ?)')
      .run('สาขาหลัก', 'MAIN');
    defaultBranch = { id: info.lastInsertRowid };
  }

  for (const table of BRANCH_SCOPED_TABLES) {
    db.prepare(`UPDATE ${table} SET branch_id = ? WHERE branch_id IS NULL`).run(defaultBranch.id);
  }

  // ให้ผู้ใช้เดิมทุกคนเข้าสาขา fallback นี้ได้ทันที ไม่งั้นจะล็อกอินไม่ได้เลยหลังอัปเกรด (admin ไม่
  // จำเป็นต้องมีแถวนี้ก็เข้าได้ทุกสาขาอยู่แล้ว แต่ใส่ให้ด้วยเพื่อความสม่ำเสมอของข้อมูล ไม่มีผลเสีย)
  const insertMembership = db.prepare(
    'INSERT OR IGNORE INTO user_branches (user_id, branch_id) VALUES (?, ?)',
  );
  for (const user of db.prepare('SELECT id FROM users').all()) {
    insertMembership.run(user.id, defaultBranch.id);
  }
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

  // Ticket 11 (multi-branch) — branch_id ผูกแค่ 4 entity นี้ (ดู docs/DECISIONS.md #36)
  addColumnIfMissing(
    db,
    'dining_tables',
    'branch_id',
    'INTEGER REFERENCES branches(id) ON DELETE SET NULL',
  );
  addColumnIfMissing(
    db,
    'menu_items',
    'branch_id',
    'INTEGER REFERENCES branches(id) ON DELETE SET NULL',
  );
  addColumnIfMissing(
    db,
    'orders',
    'branch_id',
    'INTEGER REFERENCES branches(id) ON DELETE SET NULL',
  );
  addColumnIfMissing(
    db,
    'ingredients',
    'branch_id',
    'INTEGER REFERENCES branches(id) ON DELETE SET NULL',
  );
  backfillDefaultBranch(db);

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
