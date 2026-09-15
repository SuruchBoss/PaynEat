import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) => api().post(url).set(authHeader(token)).send(body);
const patch = (url, token, body) => api().patch(url).set(authHeader(token)).send(body);

/** เปิดออเดอร์ใหม่ 1 ใบพร้อมโต๊ะว่างและเมนู 1 รายการ คืนออเดอร์ที่สร้างเสร็จ */
const openOrder = async (waiterToken, quantity = 1) => {
  const tablesRes = await get('/api/v1/tables?status=available', waiterToken);
  const table = tablesRes.body.data[0];
  assert.ok(table, 'ต้องมีโต๊ะว่างอย่างน้อย 1 โต๊ะสำหรับเทสต์นี้');

  const menuRes = await get('/api/v1/menu-items?availableOnly=true&limit=200', waiterToken);
  const menuItem = menuRes.body.data[0];
  assert.ok(menuItem, 'ต้องมีเมนูที่ขายอยู่อย่างน้อย 1 รายการสำหรับเทสต์นี้');

  const res = await post('/api/v1/orders', waiterToken, {
    type: 'dine_in',
    tableId: table.id,
    guestCount: 2,
    items: [{ menuItemId: menuItem.id, quantity, optionIds: [] }],
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return { order: res.body.data, table };
};

test('POST /payments — จ่ายเต็มจำนวนแล้วออเดอร์ปิดและโต๊ะว่างคืน', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { order, table } = await openOrder(waiter.token);

  const res = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });

  assert.equal(res.status, 201);
  assert.equal(res.body.data.isFullyPaid, true);
  assert.equal(res.body.data.order.status, 'paid');

  const tableRes = await get(`/api/v1/tables/${table.id}`, cashier.token);
  assert.equal(tableRes.body.data.status, 'available');
});

test('POST /payments — แยกจ่ายสองครั้งจนครบยอดถึงจะปิดออเดอร์', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { order } = await openOrder(waiter.token, 2);
  const half = Math.round((order.total / 2) * 100) / 100;

  const first = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'qr',
    amount: half,
  });
  assert.equal(first.status, 201);
  assert.equal(first.body.data.isFullyPaid, false);
  assert.equal(first.body.data.order.status, 'open');

  const remaining = order.total - half;
  const second = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: remaining,
    received: remaining,
  });
  assert.equal(second.status, 201);
  assert.equal(second.body.data.isFullyPaid, true);
  assert.equal(second.body.data.order.status, 'paid');
});

test('POST /payments — จ่ายเกินยอดคงเหลือต้องได้ 400', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { order } = await openOrder(waiter.token);

  const res = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total + 1000,
    received: order.total + 1000,
  });

  assert.equal(res.status, 400);
});

test('POST /payments — จ่ายซ้ำออเดอร์ที่ชำระครบแล้วต้องได้ 409', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { order } = await openOrder(waiter.token);

  await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });

  const res = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });

  assert.equal(res.status, 409);
});

test('POST /payments — จ่ายเงินสดโดยรับเงินมาน้อยกว่ายอดต้องได้ 422', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { order } = await openOrder(waiter.token);

  const res = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total - 1,
  });

  assert.equal(res.status, 422);
});

test('POST /payments — ครัวชำระเงินไม่ได้ (RBAC 403)', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const kitchen = await login('kitchen', 'kitchen123');
  const { order } = await openOrder(waiter.token);

  const res = await post('/api/v1/payments', kitchen.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });

  assert.equal(res.status, 403);
});

test('GET /payments/order/:id — สรุปยอดคงเหลือถูกต้องหลังจ่ายบางส่วน', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { order } = await openOrder(waiter.token, 2);
  const partial = Math.round((order.total / 2) * 100) / 100;

  await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'qr',
    amount: partial,
  });

  const res = await get(`/api/v1/payments/order/${order.id}`, cashier.token);

  assert.equal(res.status, 200);
  assert.equal(res.body.data.paid, partial);
  assert.equal(
    Math.round((res.body.data.remaining + Number.EPSILON) * 100) / 100,
    Math.round((order.total - partial) * 100) / 100,
  );
});

test('GET /payments/order/:id/receipt — มีข้อมูลร้านและยอดชำระครบหลังจ่ายเต็มจำนวน', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { order } = await openOrder(waiter.token);

  await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });

  const res = await get(`/api/v1/payments/order/${order.id}/receipt`, cashier.token);

  assert.equal(res.status, 200);
  assert.ok(res.body.data.store.name);
  assert.equal(res.body.data.order.id, order.id);
  assert.equal(res.body.data.payments.length, 1);
});

// ดู docs/tickets/16-promptpay-qr.md — QR พร้อมเพย์จริง แทนที่ปุ่ม "qr" ที่เคยเป็นแค่ label
test('GET /payments/promptpay-qr — ยังไม่ได้ตั้งเลขพร้อมเพย์ต้องได้ 400', async () => {
  const cashier = await login('cashier', 'cashier123');

  const res = await get('/api/v1/payments/promptpay-qr?amount=100', cashier.token);

  assert.equal(res.status, 400);
});

test('GET /payments/promptpay-qr — หลังตั้งเลขพร้อมเพย์แล้ว คืน payload ที่ยาวพอเป็น QR จริงและมี CRC ต่อท้าย', async () => {
  const admin = await login('admin', 'admin123');
  const cashier = await login('cashier', 'cashier123');
  await patch('/api/v1/settings', admin.token, { promptPayId: '0812345678' });

  const res = await get('/api/v1/payments/promptpay-qr?amount=176.55', cashier.token);

  assert.equal(res.status, 200);
  assert.equal(res.body.data.promptPayId, '0812345678');
  assert.equal(res.body.data.amount, 176.55);
  assert.match(res.body.data.payload, /^00020101021229.*6304[0-9A-F]{4}$/);
  assert.ok(res.body.data.payload.includes('5406176.55')); // tag 54 ความยาว 6 ค่า "176.55"
});

test('GET /payments/promptpay-qr — ไม่ระบุ amount ได้ static QR (ไม่มี tag 54)', async () => {
  const admin = await login('admin', 'admin123');
  const cashier = await login('cashier', 'cashier123');
  await patch('/api/v1/settings', admin.token, { promptPayId: '0812345678' });

  const res = await get('/api/v1/payments/promptpay-qr', cashier.token);

  assert.equal(res.status, 200);
  assert.equal(res.body.data.amount, null);
  assert.match(res.body.data.payload, /^00020101021129/);
});

test('GET /payments/promptpay-qr — waiter (อยู่ใน role cashier group) เรียกได้เหมือน cashier', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  await patch('/api/v1/settings', admin.token, { promptPayId: '0812345678' });

  const res = await get('/api/v1/payments/promptpay-qr?amount=50', waiter.token);

  assert.equal(res.status, 200);
});
