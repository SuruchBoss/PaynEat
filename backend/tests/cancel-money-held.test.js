// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after, before } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';
import { shiftRepository } from '../src/modules/shifts/shift.repository.js';

// ยกเลิกออเดอร์ที่ร้านยังถือเงินลูกค้าไว้ไม่ได้ (T08 #100, docs/DECISIONS.md #77 D2) — ตอบ 409 พร้อมยอดที่ต้องคืนและ payment
// ที่ยังคืนได้ คืนครบแล้วจึงยกเลิกได้ บิลขายเชื่อคืนผ่านการคืนเงินบิลขายเชื่อ (ออกใบลดหนี้ให้เอง DECISIONS #56) ไม่มีทางลดหนี้ทางที่สอง

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) =>
  api()
    .post(url)
    .set(authHeader(token))
    .send(body ?? {});
const patch = (url, token, body) => api().patch(url).set(authHeader(token)).send(body);

let waiter;
let cashier;
let manager;
let simpleMenu;

const uniq = () => `${Date.now()}${Math.floor(Math.random() * 1000)}`;

before(async () => {
  waiter = await login('waiter1', 'waiter123');
  cashier = await login('cashier', 'cashier123');
  manager = await login('manager', 'manager123');
  const menu = await get('/api/v1/menu-items?availableOnly=true&limit=200', waiter.token);
  simpleMenu = menu.body.data.filter(
    (item) =>
      !item.soldByWeight &&
      !item.optionGroups.some((group) => group.isRequired) &&
      item.price >= 50,
  );
  assert.ok(simpleMenu.length > 0, 'seed ต้องมีเมนูธรรมดาราคาอย่างน้อย 50 บาท');
});

const openDineIn = async () => {
  const table = (await get('/api/v1/tables?status=available', waiter.token)).body.data[0];
  const res = await post('/api/v1/orders', waiter.token, {
    type: 'dine_in',
    tableId: table.id,
    guestCount: 2,
    items: [{ menuItemId: simpleMenu[0].id, quantity: 3, optionIds: [] }],
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data;
};

const cancel = (order, token = manager.token) =>
  post(`/api/v1/orders/${order.id}/cancel`, token, { reason: 'ลูกค้าเปลี่ยนใจ' });
const orderOf = async (order) => (await get(`/api/v1/orders/${order.id}`, cashier.token)).body.data;
const currentShift = async () => (await get('/api/v1/shifts/current', manager.token)).body.data;
/** เงินสดที่ลิ้นชักควรมีเพิ่มจากเงินเปิดกะ: รับเงินสดเข้า − คืนเงินสดออก (สูตรเดียวกับตอนปิดกะ) */
const drawerDelta = (shiftId) =>
  shiftRepository.cashInDuring(shiftId) - shiftRepository.cashRefundedDuring(shiftId);
const refund = async (paymentId, amount) => {
  const res = await post(`/api/v1/payments/${paymentId}/refund`, manager.token, {
    amount,
    reason: 'ยกเลิกออเดอร์',
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data;
};

test('จ่ายเงินสด 100 แล้วยกเลิก → 409 บอกยอดที่ต้องคืน บิลไม่เปลี่ยน คืนบางส่วนยังยกเลิกไม่ได้ คืนครบแล้วยกเลิกได้ และลิ้นชักไม่มีเงินเกิน', async () => {
  const shift = await currentShift();
  assert.ok(shift, 'seed เปิดกะไว้ให้');
  const drawerBefore = drawerDelta(shift.id);
  const order = await openDineIn();
  const paid = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: 100,
    received: 100,
  });
  assert.equal(paid.status, 201, JSON.stringify(paid.body));
  const payment = paid.body.data.payment;

  const refused = await cancel(order);
  assert.equal(refused.status, 409, JSON.stringify(refused.body));
  assert.equal(refused.body.error.code, 'REFUND_REQUIRED');
  assert.match(refused.body.error.message, /รับเงินไว้แล้ว 100 บาท ต้องคืนเงินให้ครบก่อน/);
  assert.equal(refused.body.error.details.refundRequired, 100);
  assert.deepEqual(refused.body.error.details.payments, [
    { id: payment.id, method: 'cash', refundable: 100 },
  ]);

  const untouched = await orderOf(order);
  assert.equal(untouched.status, order.status, 'การยกเลิกที่ถูกปฏิเสธต้องไม่แตะออเดอร์');
  assert.ok(untouched.items.every((item) => item.status !== 'cancelled'));
  const table = (await get(`/api/v1/tables/${order.tableId}`, waiter.token)).body.data;
  assert.equal(table.status, 'occupied', 'โต๊ะต้องยังไม่ว่าง');

  await refund(payment.id, 60);
  const stillHeld = await cancel(order);
  assert.equal(stillHeld.status, 409);
  assert.equal(stillHeld.body.error.details.refundRequired, 40);
  assert.deepEqual(stillHeld.body.error.details.payments, [
    { id: payment.id, method: 'cash', refundable: 40 },
  ]);

  await refund(payment.id, 40);
  const cancelled = await cancel(order);
  assert.equal(cancelled.status, 200, JSON.stringify(cancelled.body));
  assert.equal(cancelled.body.data.status, 'cancelled');

  // รับเงินสด 100 แล้วคืน 100 ในกะเดียวกัน เงินที่คาดไว้ในลิ้นชักเท่าเดิม ไม่มีเงินสดที่ไม่มียอดขายรองรับ
  assert.equal(drawerDelta(shift.id), drawerBefore);
  const z = await get(`/api/v1/reports/z-report/by-shift/${shift.id}`, manager.token);
  assert.equal(z.status, 200);
});

test('ข้อความ 409 แปลตามภาษาที่แอปขอ', async () => {
  const order = await openDineIn();
  await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'qr',
    amount: 50,
  });
  const res = await api()
    .post(`/api/v1/orders/${order.id}/cancel`)
    .set(authHeader(manager.token))
    .set('Accept-Language', 'en')
    .send({ reason: 'test' });
  assert.equal(res.status, 409);
  assert.equal(
    res.body.error.message.split(' (')[0],
    'This order holds 50 THB already received — refund all of it before cancelling',
  );
});

test('ขายเชื่อ 50 แล้วยกเลิก → 409 ลดหนี้ผ่านการคืนเงินบิลขายเชื่อ (ออกใบลดหนี้) หนี้กลับเป็นเท่าเดิม แล้วจึงยกเลิกได้', async () => {
  const created = await post('/api/v1/customers', cashier.token, {
    name: `ร้านลูกค้าเชื่อ-${uniq()}`,
    phone: `08${uniq().slice(-8)}`,
  });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  const customer = (
    await patch(`/api/v1/customers/${created.body.data.id}/credit`, manager.token, {
      creditLimit: 50000,
      creditTermDays: 30,
    })
  ).body.data;
  const statement = async () =>
    (await get(`/api/v1/receivables/customers/${customer.id}`, cashier.token)).body.data;

  const opened = await post('/api/v1/orders', cashier.token, {
    type: 'takeaway',
    customerId: customer.id,
    items: [{ menuItemId: simpleMenu[0].id, quantity: 3, optionIds: [] }],
  });
  assert.equal(opened.status, 201, JSON.stringify(opened.body));
  const order = opened.body.data;
  const paid = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'credit',
    amount: 50,
  });
  assert.equal(paid.status, 201, JSON.stringify(paid.body));
  const payment = paid.body.data.payment;
  assert.equal((await statement()).outstanding, 50);

  const refused = await cancel(order);
  assert.equal(refused.status, 409, JSON.stringify(refused.body));
  assert.equal(refused.body.error.code, 'REFUND_REQUIRED');
  assert.deepEqual(refused.body.error.details.payments, [
    { id: payment.id, method: 'credit', refundable: 50 },
  ]);
  assert.equal((await statement()).outstanding, 50, 'ห้ามลดหนี้เองเงียบๆ ตอนยกเลิก');

  await refund(payment.id, 50);
  const afterRefund = await statement();
  assert.equal(afterRefund.outstanding, 0);
  assert.equal(afterRefund.creditNotes.length, 1, 'การลดหนี้ต้องออกใบลดหนี้');

  const cancelled = await cancel(order);
  assert.equal(cancelled.status, 200, JSON.stringify(cancelled.body));
  assert.equal(cancelled.body.data.status, 'cancelled');
  assert.equal((await statement()).outstanding, 0, 'บิลที่ยกเลิกต้องไม่มีหนี้ค้าง');
});
