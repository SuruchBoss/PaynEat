// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after, before } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';
import { customerRepository } from '../src/modules/customers/customer.repository.js';

// แยกเงินสดจริงออกจากมูลค่าแต้ม (T11 #101, docs/DECISIONS.md #77 D7, #99): ลิ้นชักตอนปิดกะนับเฉพาะเงินสดที่รับจริง
// รายงานช่องทางชำระแสดงเงินจริงกับบรรทัดแลกแต้มแยกกัน และคืนเงินแบ่งเป็นเงินกับแต้มตามสัดส่วนที่ลูกค้าจ่ายมา
// ค่าเริ่มต้นของร้าน: 1 แต้ม = 1 บาท

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) =>
  api()
    .post(url)
    .set(authHeader(token))
    .send(body ?? {});
const patch = (url, token, body) => api().patch(url).set(authHeader(token)).send(body);

const baht = (value) => Math.round(value * 100) / 100;
const uniq = () => `${Date.now()}${Math.floor(Math.random() * 1000)}`;

let waiter;
let cashier;
let manager;
let crispyPork; // 85 บาท → บิล 100.05

before(async () => {
  waiter = await login('waiter1', 'waiter123');
  cashier = await login('cashier', 'cashier123');
  manager = await login('manager', 'manager123');
  const menu = (await get('/api/v1/menu-items?availableOnly=true&limit=200', waiter.token)).body
    .data;
  crispyPork = menu.find((item) => item.name === 'ข้าวหมูกรอบ');
  assert.ok(crispyPork, 'seed ต้องมีข้าวหมูกรอบ 85 บาท');
});

const newCustomer = async (points) => {
  const res = await post('/api/v1/customers', cashier.token, {
    name: `ลูกค้าสะสมแต้ม-${uniq()}`,
    phone: `08${uniq().slice(-8)}`,
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  customerRepository.adjustPoints(res.body.data.id, points);
  return res.body.data;
};
const pointsOf = (customer) => customerRepository.findById(customer.id).points_balance;

const openTakeaway = async (customer) => {
  const res = await post('/api/v1/orders', cashier.token, {
    type: 'takeaway',
    guestCount: 1,
    ...(customer ? { customerId: customer.id } : {}),
    items: [{ menuItemId: crispyPork.id, quantity: 1, optionIds: [] }],
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  assert.equal(res.body.data.total, 100.05);
  return res.body.data;
};

const payCash = async (order, { amount, received, pointsToRedeem = 0 }) => {
  const res = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount,
    received,
    pointsToRedeem,
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data.payment;
};

const preview = (payment, amount) =>
  get(`/api/v1/payments/${payment.id}/refund-preview?amount=${amount}`, manager.token);
const refund = (payment, amount) =>
  post(`/api/v1/payments/${payment.id}/refund`, manager.token, { amount, reason: 'ทดสอบคืนเงิน' });

const methods = (report) =>
  Object.fromEntries(report.paymentMethods.map((row) => [row.method, row]));

let shift;
let pointsPayment;
let pointsCustomer;
let pointsAfterPaying;

test('เปิดกะ 2000 รับเงินสด 100.05 กับบิล 100.05 ที่ใช้ 40 แต้ม + เงินสด 60.05 → ลิ้นชักควรมี 2160.10 รายงานแยกเงินสดกับแต้ม', async () => {
  // เช้าวันใหม่ของร้าน: ปิดกะที่ seed ค้างไว้ แล้วเปิดกะใหม่ด้วยเงินทอน 2000
  const leftover = (await get('/api/v1/shifts/current', manager.token)).body.data;
  if (leftover) {
    const closed = await patch(`/api/v1/shifts/${leftover.id}/close`, manager.token, {
      countedCash: leftover.openingCash,
    });
    assert.equal(closed.status, 200, JSON.stringify(closed.body));
  }
  const opened = await post('/api/v1/shifts', cashier.token, { openingCash: 2000 });
  assert.equal(opened.status, 201, JSON.stringify(opened.body));
  shift = opened.body.data;
  const before = (await get('/api/v1/reports/summary', manager.token)).body.data;

  await payCash(await openTakeaway(), { amount: 100.05, received: 100.05 });
  pointsCustomer = await newCustomer(100);
  pointsPayment = await payCash(await openTakeaway(pointsCustomer), {
    amount: 100.05,
    received: 60.05,
    pointsToRedeem: 40,
  });
  // ใช้ไป 40 แต้ม (บิลที่จ่ายครบได้แต้มสะสมใหม่ตามยอดบิลด้วย)
  const order = (await get(`/api/v1/orders/${pointsPayment.orderId}`, cashier.token)).body.data;
  pointsAfterPaying = pointsOf(pointsCustomer);
  assert.equal(pointsAfterPaying, 100 - 40 + order.pointsEarned);

  const z = (await get(`/api/v1/reports/z-report/by-shift/${shift.id}`, manager.token)).body.data;
  assert.deepEqual(methods(z).cash, { method: 'cash', count: 2, amount: 160.1 });
  assert.deepEqual(methods(z).points, { method: 'points', count: 1, amount: 40 });
  assert.equal(z.netSales, 200.1);

  const after = (await get('/api/v1/reports/summary', manager.token)).body.data;
  const cashBefore = methods(before).cash?.amount ?? 0;
  const pointsBefore = methods(before).points?.amount ?? 0;
  assert.equal(baht(methods(after).cash.amount - cashBefore), 160.1, 'เงินสดในรายงาน = เงินสดจริง');
  assert.equal(baht(methods(after).points.amount - pointsBefore), 40, 'มีบรรทัดแลกแต้มแยก');

  const csv = await get('/api/v1/reports/z-report/by-shift/' + shift.id + '/export', manager.token);
  assert.equal(csv.status, 200);
  assert.match(csv.text, /"ช่องทาง: points \(1 รายการ, บาท\)",40/);
});

test('ดูตัวอย่างก่อนคืน: คืน 50 บาทจากบิลที่ใช้แต้ม แบ่งเป็นแต้ม 19 กับเงินสด 31 ตามสัดส่วน (แต้มปัดลง)', async () => {
  const res = await preview(pointsPayment, 50);
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.deepEqual(res.body.data, {
    paymentId: pointsPayment.id,
    amount: 50,
    cashAmount: 31,
    pointsReturned: 19,
    pointsValue: 19,
    refundable: 100.05,
    cashRefundable: 60.05,
    pointsRefundable: 40,
  });
  // ดูตัวอย่างไม่เขียนอะไร
  assert.equal(pointsOf(pointsCustomer), pointsAfterPaying);
  const tooMuch = await preview(pointsPayment, 100.06);
  assert.equal(tooMuch.status, 400);
});

test('คืนเต็มบิลที่ใช้แต้ม: เงินสดคืนสูงสุด 60.05 ลูกค้าได้ 40 แต้มคืน ลิ้นชักลดเฉพาะเงินสด และปิดกะได้ส่วนต่าง 0', async () => {
  const done = await refund(pointsPayment, 100.05);
  assert.equal(done.status, 201, JSON.stringify(done.body));
  assert.equal(done.body.data.amount, 100.05);
  assert.equal(done.body.data.cashAmount, 60.05);
  assert.equal(done.body.data.pointsReturned, 40);
  assert.equal(done.body.data.pointsValue, 40);
  assert.equal(
    pointsOf(pointsCustomer),
    pointsAfterPaying + 40,
    'แต้มที่ใช้ไปกลับเข้าบัญชีลูกค้าครบ',
  );

  const again = await refund(pointsPayment, 0.01);
  assert.equal(again.status, 400, 'คืนครบแล้วคืนเพิ่มไม่ได้');

  // 2000 + 100.05 + 60.05 − 60.05 ที่คืนเป็นเงินสด
  const closed = await patch(`/api/v1/shifts/${shift.id}/close`, manager.token, {
    countedCash: 2100.05,
  });
  assert.equal(closed.status, 200, JSON.stringify(closed.body));
  assert.equal(closed.body.data.expectedCash, 2100.05);
  assert.equal(closed.body.data.variance, 0);
});

test('คืนหลายรอบตามสัดส่วนรวมกันได้เท่าคืนครั้งเดียว ใบเสร็จแสดงเงินกับแต้มที่คืนแต่ละรอบ', async () => {
  const opened = await post('/api/v1/shifts', cashier.token, { openingCash: 500 });
  assert.equal(opened.status, 201, JSON.stringify(opened.body));
  const customer = await newCustomer(40);
  const order = await openTakeaway(customer);
  const payment = await payCash(order, { amount: 100.05, received: 60.05, pointsToRedeem: 40 });
  const afterPaying = pointsOf(customer);

  for (const [amount, cash, points] of [
    [50, 31, 19],
    [30, 18, 12],
    [20.05, 11.05, 9],
  ]) {
    const done = await refund(payment, amount);
    assert.equal(done.status, 201, JSON.stringify(done.body));
    assert.equal(done.body.data.cashAmount, cash, `คืน ${amount}`);
    assert.equal(done.body.data.pointsReturned, points, `คืน ${amount}`);
  }
  assert.equal(pointsOf(customer), afterPaying + 40);
  const receipt = (await get(`/api/v1/payments/order/${order.id}/receipt`, cashier.token)).body
    .data;
  assert.deepEqual(
    receipt.refunds.map((r) => [r.amount, r.cashAmount, r.pointsReturned]),
    [
      [50, 31, 19],
      [30, 18, 12],
      [20.05, 11.05, 9],
    ],
  );
});

test('การคืนเงินบิลที่ไม่ได้ใช้แต้มเป็นเงินทั้งหมดเหมือนเดิม', async () => {
  const order = await openTakeaway();
  const payment = await payCash(order, { amount: 100.05, received: 100.05 });
  const res = await preview(payment, 40);
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.equal(res.body.data.cashAmount, 40);
  assert.equal(res.body.data.pointsReturned, 0);
  const done = await refund(payment, 40);
  assert.equal(done.status, 201, JSON.stringify(done.body));
  assert.equal(done.body.data.cashAmount, 40);
});
