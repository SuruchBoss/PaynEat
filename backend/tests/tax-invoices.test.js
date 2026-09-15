import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) =>
  api()
    .post(url)
    .set(authHeader(token))
    .send(body ?? {});
const patch = (url, token, body) =>
  api()
    .patch(url)
    .set(authHeader(token))
    .send(body ?? {});

/** สร้างออเดอร์ใหม่ (1 เมนู ราคา 100 บาท) แล้วจ่ายให้ครบทันที คืน orderId ที่สถานะ 'paid' แล้ว */
const createPaidOrder = async (admin, waiter, cashier) => {
  const categoryRes = await post('/api/v1/categories', admin.token, {
    name: `หมวดทดสอบใบกำกับภาษี-${Date.now()}-${Math.random()}`,
  });
  const menuRes = await post('/api/v1/menu-items', admin.token, {
    categoryId: categoryRes.body.data.id,
    name: `เมนูทดสอบใบกำกับภาษี-${Date.now()}-${Math.random()}`,
    price: 100,
  });

  const tablesRes = await get('/api/v1/tables', waiter.token);
  const table = tablesRes.body.data.find((row) => row.status === 'available');
  assert.ok(table, 'ต้องมีโต๊ะว่างอย่างน้อย 1 โต๊ะ');

  const orderRes = await post('/api/v1/orders', waiter.token, {
    type: 'dine_in',
    tableId: table.id,
    guestCount: 1,
    items: [{ menuItemId: menuRes.body.data.id, quantity: 1, optionIds: [] }],
  });
  assert.equal(orderRes.status, 201);
  const orderId = orderRes.body.data.id;

  const sentRes = await post(`/api/v1/orders/${orderId}/send-to-kitchen`, waiter.token);
  assert.equal(sentRes.status, 200);

  const payRes = await post('/api/v1/payments', cashier.token, {
    orderId,
    method: 'qr',
    amount: sentRes.body.data.total,
    reference: `TEST-${Date.now()}`,
  });
  assert.equal(payRes.status, 201);
  assert.equal(payRes.body.data.order.status, 'paid');

  return orderId;
};

test('POST /tax-invoices/order/:id — ออกใบกำกับภาษีอย่างย่อได้เมื่อจ่ายครบแล้ว พร้อม running number', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const orderId = await createPaidOrder(admin, waiter, cashier);

  const res = await post(`/api/v1/tax-invoices/order/${orderId}`, cashier.token, {
    invoiceType: 'abbreviated',
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  const invoice = res.body.data;
  assert.equal(invoice.invoiceType, 'abbreviated');
  assert.equal(invoice.isVoid, false);
  assert.match(invoice.runningNumber, /^INV\d{2}-\d{6}$/);
  assert.equal(invoice.storeTaxId, '0105558000012');
  assert.equal(invoice.total, 117.7); // 100 + 10% service charge + 7% VAT
});

test('POST /tax-invoices/order/:id — ใบกำกับภาษีเต็มรูปต้องระบุชื่อและที่อยู่ลูกค้า', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const orderId = await createPaidOrder(admin, waiter, cashier);

  const missingRes = await post(`/api/v1/tax-invoices/order/${orderId}`, cashier.token, {
    invoiceType: 'full',
  });
  assert.equal(missingRes.status, 422);

  const okRes = await post(`/api/v1/tax-invoices/order/${orderId}`, cashier.token, {
    invoiceType: 'full',
    customerName: 'บริษัท ทดสอบ จำกัด',
    customerAddress: '99 ถนนทดสอบ กรุงเทพฯ',
  });
  assert.equal(okRes.status, 201, JSON.stringify(okRes.body));
  assert.equal(okRes.body.data.customerName, 'บริษัท ทดสอบ จำกัด');
  assert.equal(okRes.body.data.customerTaxId, null); // ไม่บังคับ
});

test('POST /tax-invoices/order/:id — ออกซ้ำไม่ได้ถ้ายังมีใบ active อยู่แล้ว', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const orderId = await createPaidOrder(admin, waiter, cashier);

  const first = await post(`/api/v1/tax-invoices/order/${orderId}`, cashier.token, {
    invoiceType: 'abbreviated',
  });
  assert.equal(first.status, 201);

  const second = await post(`/api/v1/tax-invoices/order/${orderId}`, cashier.token, {
    invoiceType: 'abbreviated',
  });
  assert.equal(second.status, 409);
});

test('POST /tax-invoices/order/:id — ออกไม่ได้ถ้าออเดอร์ยังไม่จ่ายครบ', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');

  const categoryRes = await post('/api/v1/categories', admin.token, {
    name: `หมวดทดสอบยังไม่จ่าย-${Date.now()}`,
  });
  const menuRes = await post('/api/v1/menu-items', admin.token, {
    categoryId: categoryRes.body.data.id,
    name: `เมนูทดสอบยังไม่จ่าย-${Date.now()}`,
    price: 50,
  });
  const tablesRes = await get('/api/v1/tables', waiter.token);
  const table = tablesRes.body.data.find((row) => row.status === 'available');
  const orderRes = await post('/api/v1/orders', waiter.token, {
    type: 'dine_in',
    tableId: table.id,
    guestCount: 1,
    items: [{ menuItemId: menuRes.body.data.id, quantity: 1, optionIds: [] }],
  });
  const orderId = orderRes.body.data.id;

  const res = await post(`/api/v1/tax-invoices/order/${orderId}`, cashier.token, {
    invoiceType: 'abbreviated',
  });
  assert.equal(res.status, 409);
});

test('POST /tax-invoices/order/:id — เลขที่ใบกำกับภาษีเรียงต่อเนื่องไม่ซ้ำข้ามหลายออเดอร์', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');

  const orderA = await createPaidOrder(admin, waiter, cashier);
  const orderB = await createPaidOrder(admin, waiter, cashier);

  const invoiceA = await post(`/api/v1/tax-invoices/order/${orderA}`, cashier.token, {
    invoiceType: 'abbreviated',
  });
  const invoiceB = await post(`/api/v1/tax-invoices/order/${orderB}`, cashier.token, {
    invoiceType: 'abbreviated',
  });

  const numberA = Number(invoiceA.body.data.runningNumber.split('-')[1]);
  const numberB = Number(invoiceB.body.data.runningNumber.split('-')[1]);
  assert.equal(numberB, numberA + 1);
});

test('POST /tax-invoices/order/:id — ครัวออกใบกำกับภาษีไม่ได้ (RBAC 403)', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const kitchen = await login('kitchen', 'kitchen123');
  const orderId = await createPaidOrder(admin, waiter, cashier);

  const res = await post(`/api/v1/tax-invoices/order/${orderId}`, kitchen.token, {
    invoiceType: 'abbreviated',
  });
  assert.equal(res.status, 403);
});

test('GET /tax-invoices/order/:id — 404 ถ้ายังไม่เคยออก แล้วเจอใบล่าสุดหลังออกแล้ว', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const orderId = await createPaidOrder(admin, waiter, cashier);

  const before = await get(`/api/v1/tax-invoices/order/${orderId}`, cashier.token);
  assert.equal(before.status, 404);

  await post(`/api/v1/tax-invoices/order/${orderId}`, cashier.token, {
    invoiceType: 'abbreviated',
  });

  const after1 = await get(`/api/v1/tax-invoices/order/${orderId}`, cashier.token);
  assert.equal(after1.status, 200);
  assert.equal(after1.body.data.isVoid, false);
});

test('POST /tax-invoices/order/:id/void — ยกเลิกใบที่ออกผิดแล้วออกใหม่ได้ เลขเดิมไม่ถูกใช้ซ้ำ', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const orderId = await createPaidOrder(admin, waiter, cashier);

  const first = await post(`/api/v1/tax-invoices/order/${orderId}`, cashier.token, {
    invoiceType: 'abbreviated',
  });
  const firstNumber = first.body.data.runningNumber;

  // แคชเชียร์ยกเลิกเองไม่ได้ ต้องเป็นผู้จัดการ/แอดมิน
  const forbidden = await post(`/api/v1/tax-invoices/order/${orderId}/void`, cashier.token, {
    reason: 'ทดสอบ',
  });
  assert.equal(forbidden.status, 403);

  const voidRes = await post(`/api/v1/tax-invoices/order/${orderId}/void`, admin.token, {
    reason: 'เลือกประเภทใบกำกับภาษีผิด',
  });
  assert.equal(voidRes.status, 200, JSON.stringify(voidRes.body));
  assert.equal(voidRes.body.data.isVoid, true);
  assert.equal(voidRes.body.data.voidReason, 'เลือกประเภทใบกำกับภาษีผิด');

  // ยกเลิกซ้ำ (ไม่มีใบ active ให้ยกเลิกแล้ว) ต้อง 404
  const voidAgain = await post(`/api/v1/tax-invoices/order/${orderId}/void`, admin.token, {
    reason: 'ทดสอบ',
  });
  assert.equal(voidAgain.status, 404);

  // ออกใบใหม่แทนได้ทันที เลขที่ต้องเดินหน้าต่อ ไม่ใช้เลขเดิมซ้ำ
  const reissued = await post(`/api/v1/tax-invoices/order/${orderId}`, cashier.token, {
    invoiceType: 'full',
    customerName: 'ลูกค้าทดสอบ',
    customerAddress: 'ที่อยู่ทดสอบ',
  });
  assert.equal(reissued.status, 201);
  assert.notEqual(reissued.body.data.runningNumber, firstNumber);

  const active = await get(`/api/v1/tax-invoices/order/${orderId}`, cashier.token);
  assert.equal(active.body.data.runningNumber, reissued.body.data.runningNumber);
});

test('POST /tax-invoices/order/:id — ออกไม่ได้ถ้าร้านยังไม่ตั้งค่าเลขผู้เสียภาษี/ที่อยู่', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');

  const clearRes = await patch('/api/v1/settings', admin.token, { storeTaxId: '' });
  assert.equal(clearRes.status, 200);

  const orderId = await createPaidOrder(admin, waiter, cashier);
  const res = await post(`/api/v1/tax-invoices/order/${orderId}`, cashier.token, {
    invoiceType: 'abbreviated',
  });
  assert.equal(res.status, 400);
});
