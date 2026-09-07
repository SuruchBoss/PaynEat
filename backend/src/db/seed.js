import bcrypt from 'bcryptjs';
import { getDb } from './index.js';
import { migrate } from './migrate.js';
import { toSatang } from '../core/money.js';

/**
 * ข้อมูลตัวอย่างสำหรับเดโม — รันซ้ำได้ (idempotent) เพราะเช็คก่อนว่ามีข้อมูลแล้วหรือยัง
 */
const USERS = [
  { name: 'ผู้ดูแลระบบ', username: 'admin', password: 'admin123', role: 'admin' },
  { name: 'สมชาย (ผู้จัดการ)', username: 'manager', password: 'manager123', role: 'manager' },
  { name: 'น้องฝน (พนักงานเสิร์ฟ)', username: 'waiter1', password: 'waiter123', role: 'waiter' },
  { name: 'น้องมิ้น (พนักงานเสิร์ฟ)', username: 'waiter2', password: 'waiter123', role: 'waiter' },
  { name: 'เชฟต้น (ครัว)', username: 'kitchen', password: 'kitchen123', role: 'kitchen' },
  { name: 'พี่แอน (แคชเชียร์)', username: 'cashier', password: 'cashier123', role: 'cashier' },
];

const CATEGORIES = [
  { name: 'แนะนำ', nameEn: 'Recommended', icon: '⭐', sortOrder: 1 },
  { name: 'อาหารจานเดียว', nameEn: 'Rice & Noodles', icon: '🍛', sortOrder: 2 },
  { name: 'กับข้าว', nameEn: 'Main Dishes', icon: '🍲', sortOrder: 3 },
  { name: 'ยำ / สลัด', nameEn: 'Salads', icon: '🥗', sortOrder: 4 },
  { name: 'ของทานเล่น', nameEn: 'Appetizers', icon: '🍤', sortOrder: 5 },
  { name: 'เครื่องดื่ม', nameEn: 'Drinks', icon: '🥤', sortOrder: 6 },
  { name: 'ของหวาน', nameEn: 'Desserts', icon: '🍨', sortOrder: 7 },
];

const MENU = [
  // อาหารจานเดียว
  { cat: 'อาหารจานเดียว', name: 'ข้าวผัดกุ้ง', nameEn: 'Shrimp Fried Rice', price: 90, prep: 10, recommended: true, desc: 'ข้าวผัดหอมกระทะ กุ้งสดตัวโต' },
  { cat: 'อาหารจานเดียว', name: 'ผัดกะเพราหมูสับ', nameEn: 'Basil Pork with Rice', price: 75, prep: 8, recommended: true, desc: 'เผ็ดร้อนแบบต้นตำรับ ราดข้าวสวยร้อน ๆ' },
  { cat: 'อาหารจานเดียว', name: 'ผัดไทยกุ้งสด', nameEn: 'Pad Thai with Shrimp', price: 95, prep: 12, desc: 'เส้นจันท์ผัดซอสมะขาม' },
  { cat: 'อาหารจานเดียว', name: 'ข้าวหมูกรอบ', nameEn: 'Crispy Pork with Rice', price: 85, prep: 8 },
  { cat: 'อาหารจานเดียว', name: 'ราดหน้าหมูหมัก', nameEn: 'Pork Noodles in Gravy', price: 80, prep: 10 },
  // กับข้าว
  { cat: 'กับข้าว', name: 'ต้มยำกุ้งน้ำข้น', nameEn: 'Tom Yum Goong', price: 220, prep: 15, recommended: true, desc: 'กุ้งแม่น้ำ น้ำข้นเข้มข้น' },
  { cat: 'กับข้าว', name: 'แกงเขียวหวานไก่', nameEn: 'Green Curry Chicken', price: 160, prep: 15 },
  { cat: 'กับข้าว', name: 'ปลาทับทิมนึ่งมะนาว', nameEn: 'Steamed Fish with Lime', price: 320, prep: 20 },
  { cat: 'กับข้าว', name: 'ผัดผักรวมมิตร', nameEn: 'Stir-fried Mixed Vegetables', price: 120, prep: 8 },
  { cat: 'กับข้าว', name: 'ไข่เจียวปู', nameEn: 'Crab Omelette', price: 180, prep: 10 },
  // ยำ / สลัด
  { cat: 'ยำ / สลัด', name: 'ส้มตำไทย', nameEn: 'Papaya Salad', price: 80, prep: 7, recommended: true },
  { cat: 'ยำ / สลัด', name: 'ยำวุ้นเส้นทะเล', nameEn: 'Seafood Glass Noodle Salad', price: 150, prep: 10 },
  { cat: 'ยำ / สลัด', name: 'ลาบหมู', nameEn: 'Spicy Minced Pork Salad', price: 110, prep: 10 },
  // ของทานเล่น
  { cat: 'ของทานเล่น', name: 'ปีกไก่ทอดน้ำปลา', nameEn: 'Fried Chicken Wings', price: 120, prep: 12 },
  { cat: 'ของทานเล่น', name: 'กุ้งชุบแป้งทอด', nameEn: 'Deep-fried Shrimp', price: 160, prep: 12 },
  { cat: 'ของทานเล่น', name: 'ปอเปี๊ยะทอด', nameEn: 'Spring Rolls', price: 90, prep: 8 },
  // เครื่องดื่ม
  { cat: 'เครื่องดื่ม', name: 'ชาไทยเย็น', nameEn: 'Thai Iced Tea', price: 55, prep: 3, recommended: true },
  { cat: 'เครื่องดื่ม', name: 'น้ำมะนาวโซดา', nameEn: 'Lime Soda', price: 60, prep: 3 },
  { cat: 'เครื่องดื่ม', name: 'น้ำเปล่า', nameEn: 'Drinking Water', price: 20, prep: 1 },
  { cat: 'เครื่องดื่ม', name: 'โค้ก', nameEn: 'Coke', price: 30, prep: 1 },
  { cat: 'เครื่องดื่ม', name: 'เบียร์สิงห์', nameEn: 'Singha Beer', price: 90, prep: 2 },
  // ของหวาน
  { cat: 'ของหวาน', name: 'ข้าวเหนียวมะม่วง', nameEn: 'Mango Sticky Rice', price: 120, prep: 6, recommended: true },
  { cat: 'ของหวาน', name: 'บัวลอยไข่หวาน', nameEn: 'Bua Loy', price: 70, prep: 6 },
  { cat: 'ของหวาน', name: 'ไอศกรีมกะทิ', nameEn: 'Coconut Ice Cream', price: 65, prep: 3 },
];

// ตัวเลือกเสริมของบางเมนู (ระดับความเผ็ด / ท็อปปิ้ง / ระดับความหวาน)
const OPTION_TEMPLATES = {
  spicy: {
    name: 'ระดับความเผ็ด',
    required: 1,
    min: 1,
    max: 1,
    options: [
      { name: 'ไม่เผ็ด', delta: 0, isDefault: 1 },
      { name: 'เผ็ดน้อย', delta: 0 },
      { name: 'เผ็ดปกติ', delta: 0 },
      { name: 'เผ็ดมาก', delta: 0 },
    ],
  },
  extra: {
    name: 'เพิ่มพิเศษ',
    required: 0,
    min: 0,
    max: 3,
    options: [
      { name: 'ไข่ดาว', delta: 15 },
      { name: 'เพิ่มข้าว', delta: 10 },
      { name: 'พิเศษ (เพิ่มปริมาณ)', delta: 20 },
    ],
  },
  sweet: {
    name: 'ระดับความหวาน',
    required: 1,
    min: 1,
    max: 1,
    options: [
      { name: 'หวานปกติ', delta: 0, isDefault: 1 },
      { name: 'หวานน้อย', delta: 0 },
      { name: 'ไม่หวาน', delta: 0 },
    ],
  },
  ice: {
    name: 'น้ำแข็ง',
    required: 0,
    min: 0,
    max: 1,
    options: [
      { name: 'ปกติ', delta: 0, isDefault: 1 },
      { name: 'น้อย', delta: 0 },
      { name: 'ไม่ใส่', delta: 0 },
    ],
  },
};

const MENU_OPTIONS = {
  'ผัดกะเพราหมูสับ': ['spicy', 'extra'],
  'ข้าวผัดกุ้ง': ['extra'],
  'ผัดไทยกุ้งสด': ['spicy', 'extra'],
  'ส้มตำไทย': ['spicy'],
  'ลาบหมู': ['spicy'],
  'ยำวุ้นเส้นทะเล': ['spicy'],
  'ต้มยำกุ้งน้ำข้น': ['spicy'],
  'ชาไทยเย็น': ['sweet', 'ice'],
  'น้ำมะนาวโซดา': ['sweet', 'ice'],
};

const TABLES = [
  ...Array.from({ length: 8 }, (_, i) => ({ name: `A${i + 1}`, zone: 'โซนในร้าน', seats: i < 4 ? 2 : 4 })),
  ...Array.from({ length: 6 }, (_, i) => ({ name: `B${i + 1}`, zone: 'โซนริมหน้าต่าง', seats: 4 })),
  ...Array.from({ length: 4 }, (_, i) => ({ name: `C${i + 1}`, zone: 'โซนสวน', seats: 6 })),
  { name: 'VIP1', zone: 'ห้องส่วนตัว', seats: 10 },
  { name: 'VIP2', zone: 'ห้องส่วนตัว', seats: 12 },
];

export const seed = () => {
  migrate();
  const db = getDb();

  const run = db.transaction(() => {
    const userCount = db.prepare('SELECT COUNT(*) AS c FROM users').get().c;
    if (userCount === 0) {
      const insertUser = db.prepare(
        'INSERT INTO users (name, username, password_hash, role) VALUES (?, ?, ?, ?)',
      );
      for (const user of USERS) {
        insertUser.run(user.name, user.username, bcrypt.hashSync(user.password, 10), user.role);
      }
    }

    const categoryCount = db.prepare('SELECT COUNT(*) AS c FROM categories').get().c;
    if (categoryCount === 0) {
      const insertCategory = db.prepare(
        'INSERT INTO categories (name, name_en, icon, sort_order) VALUES (?, ?, ?, ?)',
      );
      for (const category of CATEGORIES) {
        insertCategory.run(category.name, category.nameEn, category.icon, category.sortOrder);
      }
    }

    const menuCount = db.prepare('SELECT COUNT(*) AS c FROM menu_items').get().c;
    if (menuCount === 0) {
      const categoryIdByName = new Map(
        db.prepare('SELECT id, name FROM categories').all().map((row) => [row.name, row.id]),
      );
      const insertMenu = db.prepare(`
        INSERT INTO menu_items (category_id, name, name_en, description, price, is_recommended, prep_minutes, sort_order)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `);
      const insertGroup = db.prepare(`
        INSERT INTO option_groups (menu_item_id, name, min_select, max_select, is_required, sort_order)
        VALUES (?, ?, ?, ?, ?, ?)
      `);
      const insertOption = db.prepare(`
        INSERT INTO options (group_id, name, price_delta, is_default, sort_order) VALUES (?, ?, ?, ?, ?)
      `);

      MENU.forEach((item, index) => {
        const result = insertMenu.run(
          categoryIdByName.get(item.cat),
          item.name,
          item.nameEn,
          item.desc ?? null,
          toSatang(item.price),
          item.recommended ? 1 : 0,
          item.prep,
          index,
        );
        const menuItemId = result.lastInsertRowid;

        (MENU_OPTIONS[item.name] ?? []).forEach((templateKey, groupIndex) => {
          const template = OPTION_TEMPLATES[templateKey];
          const groupId = insertGroup.run(
            menuItemId,
            template.name,
            template.min,
            template.max,
            template.required,
            groupIndex,
          ).lastInsertRowid;
          template.options.forEach((option, optionIndex) => {
            insertOption.run(
              groupId,
              option.name,
              toSatang(option.delta),
              option.isDefault ?? 0,
              optionIndex,
            );
          });
        });
      });
    }

    const tableCount = db.prepare('SELECT COUNT(*) AS c FROM dining_tables').get().c;
    if (tableCount === 0) {
      const insertTable = db.prepare(
        'INSERT INTO dining_tables (name, zone, seats) VALUES (?, ?, ?)',
      );
      for (const table of TABLES) insertTable.run(table.name, table.zone, table.seats);
    }
  });

  run();
  return db;
};

if (import.meta.url === `file://${process.argv[1]}`) {
  seed();
  console.log('🌱 seed ข้อมูลตัวอย่างเรียบร้อย (บัญชีเดโม: admin/admin123, waiter1/waiter123, kitchen/kitchen123, cashier/cashier123)');
}

export default seed;
