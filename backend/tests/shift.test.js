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

/** ปิดกะที่เปิดอยู่ตอนนี้ (ถ้ามี) เพื่อให้เทสต์เริ่มจากสถานะ "ไม่มีกะเปิดอยู่" ได้ */
const closeCurrentShiftIfAny = async (managerToken) => {
  const current = await get('/api/v1/shifts/current', managerToken);
  if (!current.body.data) return;
  await patch(`/api/v1/shifts/${current.body.data.id}/close`, managerToken, {
    countedCash: current.body.data.openingCash,
  });
};

const openOrderWithItem = async (waiterToken) => {
  const tablesRes = await get('/api/v1/tables?status=available', waiterToken);
  const table = tablesRes.body.data[0];
  assert.ok(table, 'ต้องมีโต๊ะว่างอย่างน้อย 1 โต๊ะสำหรับเทสต์นี้');

  const menuRes = await get('/api/v1/menu-items?availableOnly=true&limit=200', waiterToken);
  const menuItem = menuRes.body.data[0];

  const res = await post('/api/v1/orders', waiterToken, {
    type: 'dine_in',
    tableId: table.id,
    guestCount: 1,
    items: [{ menuItemId: menuItem.id, quantity: 1, optionIds: [] }],
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data;
};

test('GET /shifts/current — มีกะที่ seed เปิดไว้ให้ตั้งแต่ต้น', async () => {
  const cashier = await login('cashier', 'cashier123');
  const res = await get('/api/v1/shifts/current', cashier.token);

  assert.equal(res.status, 200);
  assert.equal(res.body.data.status, 'open');
  assert.equal(res.body.data.openingCash, 2000);
});

test('POST /shifts — เปิดกะซ้อนขณะมีกะเปิดอยู่แล้วต้องได้ 409', async () => {
  const cashier = await login('cashier', 'cashier123');
  const res = await post('/api/v1/shifts', cashier.token, { openingCash: 1000 });
  assert.equal(res.status, 409);
});

test('POST /shifts — พนักงานเสิร์ฟเปิดกะไม่ได้ (RBAC 403)', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const res = await post('/api/v1/shifts', waiter.token, { openingCash: 1000 });
  assert.equal(res.status, 403);
});

test('PATCH /shifts/:id/close — กระทบยอดถูกต้องเมื่อเงินสดตรงกับที่ระบบคำนวณ', async () => {
  const manager = await login('manager', 'manager123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');

  const current = await get('/api/v1/shifts/current', manager.token);
  const shiftId = current.body.data.id;
  const order = await openOrderWithItem(waiter.token);

  const payRes = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });
  assert.equal(payRes.status, 201);
  assert.equal(payRes.body.data.payment.shiftId, shiftId);

  const expected = current.body.data.openingCash + order.total;
  const closeRes = await patch(`/api/v1/shifts/${shiftId}/close`, manager.token, {
    countedCash: expected,
  });

  assert.equal(closeRes.status, 200);
  assert.equal(closeRes.body.data.status, 'closed');
  assert.equal(closeRes.body.data.expectedCash, expected);
  assert.equal(closeRes.body.data.countedCash, expected);
  assert.equal(closeRes.body.data.variance, 0);
});

test('PATCH /shifts/:id/close — นับเงินขาด/เกินต้องได้ variance ติดลบ/บวกตามจริง', async () => {
  const manager = await login('manager', 'manager123');
  await closeCurrentShiftIfAny(manager.token);
  const opened = await post('/api/v1/shifts', manager.token, { openingCash: 1000 });
  const shiftId = opened.body.data.id;

  const res = await patch(`/api/v1/shifts/${shiftId}/close`, manager.token, {
    countedCash: 950,
  });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.variance, -50);
});

test('PATCH /shifts/:id/close — ปิดกะที่ปิดไปแล้วซ้ำต้องได้ 409', async () => {
  const manager = await login('manager', 'manager123');
  await closeCurrentShiftIfAny(manager.token);
  const opened = await post('/api/v1/shifts', manager.token, { openingCash: 1000 });
  const shiftId = opened.body.data.id;
  await patch(`/api/v1/shifts/${shiftId}/close`, manager.token, { countedCash: 0 });

  const res = await patch(`/api/v1/shifts/${shiftId}/close`, manager.token, { countedCash: 0 });
  assert.equal(res.status, 409);
});

test('POST /payments — ไม่มีกะเปิดอยู่ต้องรับชำระเงินไม่ได้ (409)', async () => {
  const manager = await login('manager', 'manager123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');

  await closeCurrentShiftIfAny(manager.token);
  const order = await openOrderWithItem(waiter.token);

  const res = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });

  assert.equal(res.status, 409);
});

test('GET /shifts — ดูประวัติย้อนหลังเห็นทั้งกะที่เปิดและปิดแล้ว', async () => {
  const manager = await login('manager', 'manager123');
  const res = await get('/api/v1/shifts', manager.token);

  assert.equal(res.status, 200);
  assert.ok(res.body.data.length >= 1);
  assert.ok(res.body.data.some((shift) => shift.status === 'closed'));
});
