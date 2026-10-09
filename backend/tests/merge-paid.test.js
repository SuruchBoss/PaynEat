// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after, before } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

// รวมโต๊ะแล้วยอดที่จ่ายและส่วนลดตามไปที่บิลปลายทาง (T09 #96, docs/DECISIONS.md #77 D3, #98) — บิลต้นทางปิดโดยไม่มีเงินค้าง
// ไม่ถูกนับในรายงาน และหน้าดูตัวอย่างก่อนรวมบอกยอดจ่ายแล้ว ส่วนลดของทั้งสองฝั่ง และส่วนลดที่จะหาย

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
let crispyPork; // 85 บาท → บิล 100.05 (SC 10% + VAT 7% แยก)
let gravyNoodles; // 80 บาท → บิล 94.16

before(async () => {
  waiter = await login('waiter1', 'waiter123');
  cashier = await login('cashier', 'cashier123');
  manager = await login('manager', 'manager123');
  const menu = (await get('/api/v1/menu-items?availableOnly=true&limit=200', waiter.token)).body
    .data;
  crispyPork = menu.find((item) => item.name === 'ข้าวหมูกรอบ');
  gravyNoodles = menu.find((item) => item.name === 'ราดหน้าหมูหมัก');
  assert.ok(crispyPork && gravyNoodles, 'seed ต้องมีข้าวหมูกรอบ 85 และราดหน้าหมูหมัก 80');
});

const openDineIn = async (menuItem) => {
  const table = (await get('/api/v1/tables?status=available', waiter.token)).body.data[0];
  const res = await post('/api/v1/orders', waiter.token, {
    type: 'dine_in',
    tableId: table.id,
    guestCount: 2,
    items: [{ menuItemId: menuItem.id, quantity: 1, optionIds: [] }],
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data;
};

const pay = async (order, method, amount) => {
  const res = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method,
    amount,
    ...(method === 'cash' ? { received: amount } : {}),
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data;
};

const preview = (target, source) =>
  get(`/api/v1/orders/${target.id}/merge-preview?sourceOrderId=${source.id}`, waiter.token);
const merge = (target, source) =>
  post(`/api/v1/orders/${target.id}/merge`, waiter.token, { sourceOrderId: source.id });
const orderOf = async (order) => (await get(`/api/v1/orders/${order.id}`, cashier.token)).body.data;
const summaryOf = async (order) =>
  (await get(`/api/v1/payments/order/${order.id}`, cashier.token)).body.data;
const report = async () => (await get('/api/v1/reports/summary', manager.token)).body.data;

test('A (100.05 จ่าย 50) รวมเข้า B (94.16) → ตัวอย่างบอกยอดทั้งสองฝั่ง B เหลือจ่าย 144.21 และ A ปิดโดยไม่มียอดเงินค้าง', async () => {
  const before = await report();
  const a = await openDineIn(crispyPork);
  const b = await openDineIn(gravyNoodles);
  assert.equal(a.total, 100.05);
  assert.equal(b.total, 94.16);
  await pay(a, 'cash', 50);

  const shown = await preview(b, a);
  assert.equal(shown.status, 200, JSON.stringify(shown.body));
  assert.deepEqual(
    {
      target: {
        code: shown.body.data.target.code,
        total: shown.body.data.target.total,
        paid: shown.body.data.target.paid,
      },
      source: {
        code: shown.body.data.source.code,
        total: shown.body.data.source.total,
        paid: shown.body.data.source.paid,
      },
      total: shown.body.data.merged.total,
      paid: shown.body.data.merged.paid,
      remaining: shown.body.data.merged.remaining,
      refundRequired: shown.body.data.merged.refundRequired,
      discountLost: shown.body.data.discountLost,
    },
    {
      target: { code: b.code, total: 94.16, paid: 0 },
      source: { code: a.code, total: 100.05, paid: 50 },
      total: 194.21,
      paid: 50,
      remaining: 144.21,
      refundRequired: 0,
      discountLost: 0,
    },
  );

  const merged = await merge(b, a);
  assert.equal(merged.status, 200, JSON.stringify(merged.body));
  assert.equal(merged.body.data.total, 194.21);
  const target = await summaryOf(b);
  assert.equal(target.paid, 50);
  assert.equal(target.remaining, 144.21);
  assert.equal(target.payments.length, 1, 'การชำระของ A ย้ายมาอยู่ที่ B');

  const source = await orderOf(a);
  assert.equal(source.status, 'cancelled');
  assert.equal(source.total, 0, 'บิลต้นทางไม่มียอดเหลือ');
  assert.equal(source.items.length, 0);
  const sourceMoney = await summaryOf(a);
  assert.equal(sourceMoney.paid, 0, 'บิลต้นทางไม่มีเงินค้าง');
  assert.equal(sourceMoney.payments.length, 0);

  const closed = await pay(b, 'cash', 144.21);
  assert.equal(closed.isFullyPaid, true);
  const after = await report();
  assert.equal(after.orderCount - before.orderCount, 1, 'นับเฉพาะบิลปลายทาง');
  assert.equal(baht(after.netSales - before.netSales), 194.21);
});

test('ส่วนลด 10 บาทของ A ตามไปที่บิลปลายทาง ไม่หายเงียบ', async () => {
  const a = await openDineIn(crispyPork);
  const b = await openDineIn(gravyNoodles);
  const discounted = await post(`/api/v1/orders/${a.id}/discount`, cashier.token, {
    type: 'amount',
    value: 10,
  });
  assert.equal(discounted.status, 200, JSON.stringify(discounted.body));
  assert.equal(discounted.body.data.total, 88.28);

  const shown = (await preview(b, a)).body.data;
  assert.equal(shown.source.discount, 10);
  assert.equal(shown.merged.discount, 10);
  assert.equal(shown.merged.total, 182.44);
  assert.equal(shown.discountLost, 0);

  const merged = await merge(b, a);
  assert.equal(merged.status, 200, JSON.stringify(merged.body));
  assert.equal(merged.body.data.discountAmount, 10);
  assert.equal(merged.body.data.total, 182.44);
});

test('เงินที่คืนไปแล้วบนบิลต้นทางย้ายตามไปด้วย ยอดจ่ายแล้วของปลายทางเป็นยอดสุทธิ', async () => {
  const a = await openDineIn(crispyPork);
  const b = await openDineIn(gravyNoodles);
  const paid = await pay(a, 'cash', 50);
  const refunded = await post(`/api/v1/payments/${paid.payment.id}/refund`, manager.token, {
    amount: 20,
    reason: 'รับเงินเกิน',
  });
  assert.equal(refunded.status, 201, JSON.stringify(refunded.body));

  assert.equal((await preview(b, a)).body.data.merged.paid, 30);
  assert.equal((await merge(b, a)).status, 200);
  const target = await summaryOf(b);
  assert.equal(target.paid, 30);
  assert.equal(target.refunded, 20);
  assert.equal(target.remaining, 164.21);
});

test('โปรโมชันประเมินใหม่บนบิลที่รวมแล้ว: โค้ดของปลายทางชนะ ส่วนลดของต้นทางที่หายบอกในตัวอย่าง และโค้ดของต้นทางตามไปเมื่อปลายทางไม่มีโค้ด', async () => {
  const promo = async (value) => {
    const code = `T09${value}${uniq()}`.slice(0, 20);
    const res = await post('/api/v1/promotions', manager.token, {
      name: `ลด ${value}% (T09)`,
      type: 'percent',
      value,
      code,
    });
    assert.equal(res.status, 201, JSON.stringify(res.body));
    return { ...res.body.data, code };
  };
  const redeem = async (order, code) => {
    const res = await post(`/api/v1/orders/${order.id}/promotion/redeem`, waiter.token, { code });
    assert.equal(res.status, 200, JSON.stringify(res.body));
    return res.body.data;
  };
  const ten = await promo(10);
  const twenty = await promo(20);

  const a = await openDineIn(crispyPork);
  const b = await openDineIn(gravyNoodles);
  await redeem(a, ten.code); // ลด 8.50
  await redeem(b, twenty.code); // ลด 16.00
  const shown = (await preview(b, a)).body.data;
  assert.equal(shown.source.promotionDiscount, 8.5);
  assert.equal(shown.target.promotionDiscount, 16);
  assert.equal(shown.merged.promotionName, twenty.name);
  assert.equal(shown.merged.promotionDiscount, 33, '20% ของ 165');
  assert.equal(shown.discountLost, 0, 'ใช้โค้ด 20% กับทั้งบิล ส่วนลดรวมไม่ลดลง');
  const merged = await merge(b, a);
  assert.equal(merged.body.data.promotionName, twenty.name);
  assert.equal(merged.body.data.promotionDiscountAmount, 33);

  const c = await openDineIn(crispyPork);
  const d = await openDineIn(gravyNoodles);
  await redeem(c, twenty.code); // ลด 17.00
  await redeem(d, ten.code); // ลด 8.00
  const lost = (await preview(d, c)).body.data;
  assert.equal(lost.merged.promotionName, ten.name, 'โค้ดของปลายทางชนะ');
  assert.equal(lost.merged.promotionDiscount, 16.5);
  assert.equal(lost.discountLost, 8.5, '17 + 8 ก่อนรวม เหลือ 16.50');

  const e = await openDineIn(crispyPork);
  const f = await openDineIn(gravyNoodles);
  await redeem(e, ten.code);
  const carried = await merge(f, e);
  assert.equal(carried.status, 200, JSON.stringify(carried.body));
  assert.equal(
    carried.body.data.promotionName,
    ten.name,
    'โค้ดของต้นทางตามไปเมื่อปลายทางไม่มีโค้ด',
  );
  assert.equal(carried.body.data.promotionDiscountAmount, 16.5);
});

test('บิลที่ขายเชื่อให้ลูกค้าไว้แล้วรวมเข้าบิลที่ไม่ใช่ลูกค้าคนเดียวกันไม่ได้ ข้อมูลทั้งสองบิลไม่เปลี่ยน', async () => {
  const created = await post('/api/v1/customers', cashier.token, {
    name: `ร้านลูกค้าเชื่อ-${uniq()}`,
    phone: `08${uniq().slice(-8)}`,
  });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  const customer = created.body.data;
  await patch(`/api/v1/customers/${customer.id}/credit`, manager.token, {
    creditLimit: 50000,
    creditTermDays: 30,
  });
  const opened = await post('/api/v1/orders', cashier.token, {
    type: 'takeaway',
    customerId: customer.id,
    items: [{ menuItemId: crispyPork.id, quantity: 1, optionIds: [] }],
  });
  assert.equal(opened.status, 201, JSON.stringify(opened.body));
  const a = opened.body.data;
  await pay(a, 'credit', 50);
  const b = await openDineIn(gravyNoodles);

  for (const res of [await preview(b, a), await merge(b, a)]) {
    assert.equal(res.status, 409, JSON.stringify(res.body));
    assert.equal(res.body.error.code, 'MERGE_CUSTOMER_MISMATCH');
  }
  assert.equal((await summaryOf(a)).paid, 50);
  assert.equal((await orderOf(a)).status, a.status);
  assert.equal((await orderOf(b)).items.length, 1);
});
