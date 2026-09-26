// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

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

// ---------------------------------------------------------------------------
// เงินสดที่คืนลูกค้าต้องออกจากลิ้นชักของกะที่ "เปิดอยู่ตอนคืน" (docs/DECISIONS.md #44)
// เดิมยอดที่คาดไว้ตอนปิดกะนับแค่เงินสดที่รับเข้า ไม่หักเงินสดที่คืนออกไป แคชเชียร์ที่นับเงินถูกต้อง
// จึงถูกบันทึกว่าเงินขาดเท่ากับยอดที่ผู้จัดการคืนลูกค้าไป — เจอจากชุด E2E ใน app/test_e2e/
// ---------------------------------------------------------------------------

/** เปิดกะใหม่ด้วยเงินทอนตั้งต้นที่กำหนด (ปิดกะที่ค้างอยู่ก่อนถ้ามี) */
const openFreshShift = async (managerToken, openingCash) => {
  await closeCurrentShiftIfAny(managerToken);
  const res = await post('/api/v1/shifts', managerToken, { openingCash });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data;
};

const payInFull = async (cashierToken, order, method) => {
  const res = await post('/api/v1/payments', cashierToken, {
    orderId: order.id,
    method,
    amount: order.total,
    ...(method === 'cash' ? { received: order.total } : { reference: `T-${Date.now()}` }),
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data.payment;
};

const refundPayment = (managerToken, paymentId, amount) =>
  post(`/api/v1/payments/${paymentId}/refund`, managerToken, {
    amount,
    reason: 'ทดสอบคืนเงิน',
  });

test('PATCH /shifts/:id/close — เงินสดที่คืนลูกค้าระหว่างกะถูกหักจากยอดที่คาดไว้ นับตรงต้องไม่ขาด', async () => {
  const manager = await login('manager', 'manager123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');

  const shift = await openFreshShift(manager.token, 500);
  const order = await openOrderWithItem(waiter.token);
  const payment = await payInFull(cashier.token, order, 'cash');

  const refundRes = await refundPayment(manager.token, payment.id, 20);
  assert.equal(refundRes.status, 201, JSON.stringify(refundRes.body));

  const inDrawer = Math.round((500 + order.total - 20) * 100) / 100;
  const closeRes = await patch(`/api/v1/shifts/${shift.id}/close`, manager.token, {
    countedCash: inDrawer,
  });
  assert.equal(closeRes.status, 200, JSON.stringify(closeRes.body));
  assert.equal(closeRes.body.data.expectedCash, inDrawer);
  assert.equal(closeRes.body.data.variance, 0);
});

test('PATCH /shifts/:id/close — คืนเงินสดของบิลจากกะก่อน หักจากลิ้นชักของกะที่คืน ไม่ใช่กะที่รับเงินมา', async () => {
  const manager = await login('manager', 'manager123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');

  const morning = await openFreshShift(manager.token, 1000);
  const order = await openOrderWithItem(waiter.token);
  const payment = await payInFull(cashier.token, order, 'cash');
  const closedMorning = await patch(`/api/v1/shifts/${morning.id}/close`, manager.token, {
    countedCash: 1000 + order.total,
  });
  assert.equal(closedMorning.body.data.variance, 0);

  // ลูกค้ากลับมาขอคืนเงินตอนกะบ่าย — เงินออกจากลิ้นชักกะบ่าย
  const afternoon = await openFreshShift(manager.token, 300);
  const refundRes = await refundPayment(manager.token, payment.id, 10);
  assert.equal(refundRes.status, 201, JSON.stringify(refundRes.body));

  const closedAfternoon = await patch(`/api/v1/shifts/${afternoon.id}/close`, manager.token, {
    countedCash: 290,
  });
  assert.equal(closedAfternoon.body.data.expectedCash, 290);
  assert.equal(closedAfternoon.body.data.variance, 0);

  // กะเช้าปิดไปแล้ว ตัวเลขที่บันทึกไว้ต้องไม่ถูกแก้ย้อนหลัง
  const morningAfter = await get(`/api/v1/shifts`, manager.token);
  const row = morningAfter.body.data.find((s) => s.id === morning.id);
  assert.equal(row.variance, 0);
});

test('POST /payments/:id/refund — ไม่มีกะเปิดอยู่ คืนเงินสดไม่ได้ (409) เหมือนรับเงินสดไม่ได้', async () => {
  const manager = await login('manager', 'manager123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');

  await openFreshShift(manager.token, 0);
  const order = await openOrderWithItem(waiter.token);
  const payment = await payInFull(cashier.token, order, 'cash');
  await closeCurrentShiftIfAny(manager.token);

  const res = await refundPayment(manager.token, payment.id, 5);
  assert.equal(res.status, 409, JSON.stringify(res.body));
});

test('POST /payments/:id/refund — คืนเงินที่จ่ายผ่าน QR ได้แม้ไม่มีกะเปิด เพราะไม่แตะลิ้นชัก', async () => {
  const manager = await login('manager', 'manager123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');

  await openFreshShift(manager.token, 0);
  const order = await openOrderWithItem(waiter.token);
  const payment = await payInFull(cashier.token, order, 'qr');
  await closeCurrentShiftIfAny(manager.token);

  const res = await refundPayment(manager.token, payment.id, 5);
  assert.equal(res.status, 201, JSON.stringify(res.body));
});
