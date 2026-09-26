// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) => api().post(url).set(authHeader(token)).send(body);

const today = () => new Date().toISOString().slice(0, 10);

/** เปิดออเดอร์ 1 ใบแล้วจ่ายเต็มจำนวนทันที ให้มีข้อมูลยอดขายจริงสำหรับทดสอบ export/Z-report
 * (mirror ของ tests/reports.test.js) */
const payOffOneOrder = async (waiterToken, cashierToken, quantity = 1) => {
  const tablesRes = await get('/api/v1/tables?status=available', waiterToken);
  const table = tablesRes.body.data[0];
  assert.ok(table, 'ต้องมีโต๊ะว่างอย่างน้อย 1 โต๊ะสำหรับเทสต์นี้');

  const menuRes = await get('/api/v1/menu-items?availableOnly=true&limit=200', waiterToken);
  const menuItem = menuRes.body.data[0];
  assert.ok(menuItem, 'ต้องมีเมนูที่ขายอยู่อย่างน้อย 1 รายการสำหรับเทสต์นี้');

  const order = await post('/api/v1/orders', waiterToken, {
    type: 'dine_in',
    tableId: table.id,
    guestCount: 2,
    items: [{ menuItemId: menuItem.id, quantity, optionIds: [] }],
  });
  assert.equal(order.status, 201);

  const payment = await post('/api/v1/payments', cashierToken, {
    orderId: order.body.data.id,
    method: 'cash',
    amount: order.body.data.total,
    received: order.body.data.total,
  });
  assert.equal(payment.status, 201);
  return { order: order.body.data, menuItem };
};

test('GET /reports/export/summary — ได้ไฟล์ CSV ที่มี BOM และแถวยอดขาย', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const manager = await login('manager', 'manager123');

  await payOffOneOrder(waiter.token, cashier.token);

  const res = await get(
    `/api/v1/reports/export/summary?from=${today()}&to=${today()}`,
    manager.token,
  );

  assert.equal(res.status, 200);
  assert.match(res.headers['content-type'], /text\/csv/);
  assert.match(res.headers['content-disposition'], /sales-summary\.csv/);
  assert.equal(res.text.charCodeAt(0), 0xfeff);
  assert.match(res.text, /รายการ,มูลค่า/);
  assert.match(res.text, /ยอดขายสุทธิ/);
});

test('GET /reports/export/top-items — ได้ไฟล์ CSV ที่มีชื่อเมนูที่เพิ่งขาย', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const manager = await login('manager', 'manager123');

  const { menuItem } = await payOffOneOrder(waiter.token, cashier.token, 2);

  const res = await get(
    `/api/v1/reports/export/top-items?from=${today()}&to=${today()}&limit=50`,
    manager.token,
  );

  assert.equal(res.status, 200);
  assert.ok(res.text.includes(menuItem.name));
});

test('GET /reports/export/sales-by-day — ได้ไฟล์ CSV ที่มีแถวของวันนี้', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const manager = await login('manager', 'manager123');

  await payOffOneOrder(waiter.token, cashier.token);

  const res = await get(
    `/api/v1/reports/export/sales-by-day?from=${today()}&to=${today()}`,
    manager.token,
  );

  assert.equal(res.status, 200);
  assert.ok(res.text.includes(today()));
});

test('GET /reports/z-report/by-shift/:id — สรุปยอด+กระทบยอดเงินสดของกะปัจจุบัน', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const manager = await login('manager', 'manager123');

  const current = await get('/api/v1/shifts/current', manager.token);
  const shiftId = current.body.data?.id;
  assert.ok(shiftId, 'ต้องมีกะเปิดอยู่ก่อนเทสต์นี้ (seed เปิดไว้ให้เป็นค่าเริ่มต้น)');

  const { order } = await payOffOneOrder(waiter.token, cashier.token);

  const res = await get(`/api/v1/reports/z-report/by-shift/${shiftId}`, manager.token);

  assert.equal(res.status, 200);
  assert.equal(res.body.data.type, 'shift');
  assert.equal(res.body.data.shift.id, shiftId);
  assert.ok(res.body.data.netSales >= order.total);
  assert.ok(res.body.data.paymentMethods.some((p) => p.method === 'cash'));
  assert.equal(typeof res.body.data.shift.openingCash, 'number');
});

test('GET /reports/z-report/by-shift/:id — 404 ถ้าไม่พบกะ', async () => {
  const { token } = await login('manager', 'manager123');

  const res = await get('/api/v1/reports/z-report/by-shift/999999', token);

  assert.equal(res.status, 404);
});

test('GET /reports/z-report/by-date — เท่ากับ summary ของวันนั้นบวกฟิลด์ type/date', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const manager = await login('manager', 'manager123');

  await payOffOneOrder(waiter.token, cashier.token);

  const [z, summary] = await Promise.all([
    get(`/api/v1/reports/z-report/by-date?date=${today()}`, manager.token),
    get(`/api/v1/reports/summary?from=${today()}&to=${today()}`, manager.token),
  ]);

  assert.equal(z.status, 200);
  assert.equal(z.body.data.type, 'date');
  assert.equal(z.body.data.date, today());
  assert.equal(z.body.data.orderCount, summary.body.data.orderCount);
  assert.equal(z.body.data.netSales, summary.body.data.netSales);
});

test('GET /reports/z-report/by-date/export — ได้ไฟล์ CSV ของ Z-report รายวัน', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const manager = await login('manager', 'manager123');

  await payOffOneOrder(waiter.token, cashier.token);

  const res = await get(`/api/v1/reports/z-report/by-date/export?date=${today()}`, manager.token);

  assert.equal(res.status, 200);
  assert.match(res.headers['content-type'], /text\/csv/);
  assert.match(res.text, /ประเภท,รายวัน|รายวัน/);
  assert.match(res.text, /ยอดขายสุทธิ/);
});

test('GET /reports/export/summary — พนักงานเสิร์ฟ export ไม่ได้ (RBAC 403)', async () => {
  const { token } = await login('waiter1', 'waiter123');

  const res = await get(`/api/v1/reports/export/summary?from=${today()}&to=${today()}`, token);

  assert.equal(res.status, 403);
});
