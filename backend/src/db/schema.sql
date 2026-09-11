-- =============================================================
-- PaynEat POS — Database schema (SQLite)
-- หมายเหตุ: จำนวนเงินทุกคอลัมน์เก็บเป็น "สตางค์" (integer)
--          เช่น 120.50 บาท = 12050 เพื่อเลี่ยงปัญหา floating point
-- =============================================================

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT    NOT NULL,
  username      TEXT    NOT NULL UNIQUE,
  password_hash TEXT    NOT NULL,
  role          TEXT    NOT NULL CHECK (role IN ('admin', 'manager', 'waiter', 'cashier', 'kitchen')),
  is_active     INTEGER NOT NULL DEFAULT 1,
  created_at    TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS categories (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT    NOT NULL,
  name_en    TEXT,
  icon       TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active  INTEGER NOT NULL DEFAULT 1,
  created_at TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS menu_items (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id    INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  name           TEXT    NOT NULL,
  name_en        TEXT,
  description    TEXT,
  price          INTEGER NOT NULL CHECK (price >= 0),
  image_url      TEXT,
  is_available   INTEGER NOT NULL DEFAULT 1,
  is_recommended INTEGER NOT NULL DEFAULT 0,
  prep_minutes   INTEGER NOT NULL DEFAULT 10,
  sort_order     INTEGER NOT NULL DEFAULT 0,
  created_at     TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at     TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON menu_items(category_id);

-- กลุ่มตัวเลือกของเมนู เช่น "ระดับความเผ็ด", "เพิ่มท็อปปิ้ง"
CREATE TABLE IF NOT EXISTS option_groups (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  menu_item_id INTEGER NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
  name         TEXT    NOT NULL,
  min_select   INTEGER NOT NULL DEFAULT 0,
  max_select   INTEGER NOT NULL DEFAULT 1,
  is_required  INTEGER NOT NULL DEFAULT 0,
  sort_order   INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_option_groups_item ON option_groups(menu_item_id);

CREATE TABLE IF NOT EXISTS options (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id    INTEGER NOT NULL REFERENCES option_groups(id) ON DELETE CASCADE,
  name        TEXT    NOT NULL,
  price_delta INTEGER NOT NULL DEFAULT 0,
  is_default  INTEGER NOT NULL DEFAULT 0,
  sort_order  INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_options_group ON options(group_id);

-- วัตถุดิบ/สต๊อก (ดู docs/tickets/06-inventory-stock.md) — หน่วย (unit) เป็น string อิสระที่ร้าน
-- ตั้งเอง เช่น "กก.", "ลิตร", "ชิ้น" ไม่มี unit conversion ข้ามหน่วย — ไม่ใช่เงินจึงเก็บเป็น REAL
-- ตรง ๆ ไม่ผ่าน toSatang/toBaht เหมือนคอลัมน์เงินอื่นในระบบ (ดู docs/DECISIONS.md)
CREATE TABLE IF NOT EXISTS ingredients (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  name                TEXT    NOT NULL,
  unit                TEXT    NOT NULL,
  current_stock       REAL    NOT NULL DEFAULT 0,
  low_stock_threshold REAL    NOT NULL DEFAULT 0,
  created_at          TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at          TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ผูกเมนูกับวัตถุดิบที่ใช้ + ปริมาณที่ใช้ต่อ 1 ที่ (qty_per_unit) — เมนูหนึ่งผูกได้หลายวัตถุดิบ
-- ON DELETE RESTRICT ที่ ingredient_id: ลบวัตถุดิบที่ยังผูกกับเมนูอยู่ไม่ได้ต้องเลิกผูกก่อน
CREATE TABLE IF NOT EXISTS menu_item_ingredients (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  menu_item_id  INTEGER NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
  ingredient_id INTEGER NOT NULL REFERENCES ingredients(id) ON DELETE RESTRICT,
  qty_per_unit  REAL    NOT NULL CHECK (qty_per_unit > 0),
  created_at    TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_menu_item_ingredients_unique
  ON menu_item_ingredients(menu_item_id, ingredient_id);
CREATE INDEX IF NOT EXISTS idx_menu_item_ingredients_menu_item ON menu_item_ingredients(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_menu_item_ingredients_ingredient ON menu_item_ingredients(ingredient_id);

CREATE TABLE IF NOT EXISTS dining_tables (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT    NOT NULL UNIQUE,
  zone       TEXT    NOT NULL DEFAULT 'main',
  seats      INTEGER NOT NULL DEFAULT 4,
  status     TEXT    NOT NULL DEFAULT 'available'
             CHECK (status IN ('available', 'occupied', 'reserved', 'billing')),
  is_active  INTEGER NOT NULL DEFAULT 1,
  created_at TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- โปรโมชัน/ส่วนลดแบบมีเงื่อนไข (ดู docs/tickets/05-promotion-engine.md)
-- conditions_json: {daysOfWeek:[0-6], startTime:"HH:mm", endTime:"HH:mm",
--                    categoryIds:[...], menuItemIds:[...], minSubtotal: สตางค์}
-- ไม่ระบุ categoryIds/menuItemIds เลย = ใช้ได้กับทั้งบิล
CREATE TABLE IF NOT EXISTS promotions (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  name            TEXT    NOT NULL,
  type            TEXT    NOT NULL CHECK (type IN ('percent', 'amount', 'bogo')),
  value           INTEGER NOT NULL DEFAULT 0,
  code            TEXT    UNIQUE,
  conditions_json TEXT    NOT NULL DEFAULT '{}',
  is_active       INTEGER NOT NULL DEFAULT 1,
  valid_from      TEXT,
  valid_to        TEXT,
  created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_promotions_active ON promotions(is_active);

CREATE TABLE IF NOT EXISTS orders (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  code              TEXT    NOT NULL UNIQUE,
  type              TEXT    NOT NULL DEFAULT 'dine_in' CHECK (type IN ('dine_in', 'takeaway', 'delivery')),
  table_id          INTEGER REFERENCES dining_tables(id) ON DELETE SET NULL,
  waiter_id         INTEGER REFERENCES users(id) ON DELETE SET NULL,
  guest_count       INTEGER NOT NULL DEFAULT 1,
  status            TEXT    NOT NULL DEFAULT 'open'
                    CHECK (status IN ('open', 'in_kitchen', 'served', 'paid', 'cancelled')),
  note              TEXT,
  subtotal          INTEGER NOT NULL DEFAULT 0,
  discount_type     TEXT    NOT NULL DEFAULT 'none' CHECK (discount_type IN ('none', 'amount', 'percent')),
  discount_value    INTEGER NOT NULL DEFAULT 0,
  discount_amount   INTEGER NOT NULL DEFAULT 0,
  -- ส่วนลดจากโปรโมชัน — แยกจากส่วนลดมือข้างบน คำนวณรวมกันแต่ไม่เกิน subtotal (ดู order.calculator.js)
  promotion_id              INTEGER REFERENCES promotions(id) ON DELETE SET NULL,
  promotion_name_snapshot   TEXT,
  promotion_code_snapshot   TEXT,
  promotion_discount_amount INTEGER NOT NULL DEFAULT 0,
  service_charge    INTEGER NOT NULL DEFAULT 0,
  vat               INTEGER NOT NULL DEFAULT 0,
  total             INTEGER NOT NULL DEFAULT 0,
  cancelled_reason  TEXT,
  created_at        TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at        TEXT    NOT NULL DEFAULT (datetime('now')),
  closed_at         TEXT
);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_table ON orders(table_id);
CREATE INDEX IF NOT EXISTS idx_orders_created ON orders(created_at);

CREATE TABLE IF NOT EXISTS order_items (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id      INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id  INTEGER REFERENCES menu_items(id) ON DELETE SET NULL,
  name_snapshot TEXT    NOT NULL,
  unit_price    INTEGER NOT NULL,
  quantity      INTEGER NOT NULL CHECK (quantity > 0),
  options_json  TEXT    NOT NULL DEFAULT '[]',
  options_price INTEGER NOT NULL DEFAULT 0,
  line_total    INTEGER NOT NULL DEFAULT 0,
  note          TEXT,
  status        TEXT    NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'cooking', 'ready', 'served', 'cancelled')),
  is_paid       INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_status ON order_items(status);

-- กะทำงานของแคชเชียร์ — ใช้กระทบยอดเงินสดตอนปิดกะ (ดู docs/tickets/01-shift-cash-reconciliation.md)
CREATE TABLE IF NOT EXISTS shifts (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  status         TEXT    NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  opened_by      INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  opened_at      TEXT    NOT NULL DEFAULT (datetime('now')),
  opening_cash   INTEGER NOT NULL CHECK (opening_cash >= 0),
  closed_by      INTEGER REFERENCES users(id) ON DELETE SET NULL,
  closed_at      TEXT,
  expected_cash  INTEGER,
  counted_cash   INTEGER,
  variance       INTEGER,
  note           TEXT
);
CREATE INDEX IF NOT EXISTS idx_shifts_status ON shifts(status);

CREATE TABLE IF NOT EXISTS payments (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id      INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  shift_id      INTEGER REFERENCES shifts(id) ON DELETE SET NULL,
  method        TEXT    NOT NULL CHECK (method IN ('cash', 'qr', 'card', 'transfer')),
  amount        INTEGER NOT NULL CHECK (amount >= 0),
  received      INTEGER NOT NULL DEFAULT 0,
  change_amount INTEGER NOT NULL DEFAULT 0,
  reference     TEXT,
  cashier_id    INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_payments_order ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_shift ON payments(shift_id);

-- คืนเงินหลังชำระเงินแล้ว — แยกจาก payment เดิมเสมอเพื่อเก็บ audit trail
-- (ดู docs/tickets/02-refund-flow.md)
CREATE TABLE IF NOT EXISTS refunds (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  payment_id  INTEGER NOT NULL REFERENCES payments(id) ON DELETE RESTRICT,
  order_id    INTEGER NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
  amount      INTEGER NOT NULL CHECK (amount > 0),
  reason      TEXT    NOT NULL,
  refunded_by INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_refunds_payment ON refunds(payment_id);
CREATE INDEX IF NOT EXISTS idx_refunds_order ON refunds(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_created ON payments(created_at);

CREATE TABLE IF NOT EXISTS settings (
  key        TEXT PRIMARY KEY,
  value      TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ใบกำกับภาษี (ดู docs/tickets/07-tax-invoice.md) — แยกจากใบเสร็จปกติ (payments/receipt) เพราะมี
-- ข้อกำหนดตามกฎหมาย (ประมวลรัษฎากร มาตรา 86/4 เต็มรูป, มาตรา 86/6 อย่างย่อ) ที่ running number
-- ต้องเรียงต่อเนื่องไม่ซ้ำ/ไม่ข้าม จึง snapshot ข้อมูลร้าน+ยอดเงิน ณ เวลาที่ออกไว้ตรงนี้เลย
-- (เหมือน promotion_name_snapshot ดู docs/DECISIONS.md #14) ไม่อ้างอิงไปที่ settings/orders
-- เพราะสองตารางนั้นแก้ไขได้ภายหลัง จะทำให้ใบกำกับภาษีเก่าแสดงข้อมูลผิดเพี้ยนไปจากตอนออกจริง
CREATE TABLE IF NOT EXISTS tax_invoices (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id          INTEGER NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
  running_number    TEXT    NOT NULL UNIQUE,
  invoice_type      TEXT    NOT NULL CHECK (invoice_type IN ('abbreviated', 'full')),
  customer_name     TEXT,
  customer_address  TEXT,
  customer_tax_id   TEXT,
  store_name        TEXT    NOT NULL,
  store_tax_id      TEXT    NOT NULL,
  store_address     TEXT    NOT NULL,
  store_branch      TEXT,
  subtotal          INTEGER NOT NULL,
  vat               INTEGER NOT NULL,
  total             INTEGER NOT NULL,
  issued_by         INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  issued_at         TEXT    NOT NULL DEFAULT (datetime('now')),
  voided_at         TEXT,
  void_reason       TEXT,
  voided_by         INTEGER REFERENCES users(id) ON DELETE SET NULL
);
-- ออกได้แค่ 1 ใบ "active" (ยังไม่ถูกยกเลิก) ต่อออเดอร์ ณ ขณะใดขณะหนึ่ง — ยกเลิกใบเดิมก่อนแล้วออกใหม่ได้
-- แต่เลขที่รันไปแล้วจะไม่ถูกใช้ซ้ำแม้ใบนั้นจะถูกยกเลิก (ต้องรักษาลำดับเลขที่ให้ต่อเนื่องไม่มีช่องว่างที่อธิบายไม่ได้)
CREATE UNIQUE INDEX IF NOT EXISTS idx_tax_invoices_active_order
  ON tax_invoices(order_id) WHERE voided_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tax_invoices_order ON tax_invoices(order_id);
