// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after, before } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

// ยอดขายสุทธิในรายงานหักเฉพาะเงินที่คืนหลังบิลปิด (#143, docs/DECISIONS.md #97) — เงินที่คืนตอนบิลยังเปิดถูกเก็บกลับมาแล้ว
// ก่อนบิลจะปิด (T06, DECISIONS #87) และบิลที่ยกเลิกไม่ใช่ยอดขาย การคืนเงินของบิลนั้นจึงไม่ลดยอดขาย ทั้ง 3 endpoint ใช้กติกาเดียวกัน
// และช่องทางชำระเงินนับเงินที่ร้านเก็บไว้จริงตอนบิลปิด (payment หักเงินที่คืนก่อนปิด) ให้อยู่บนฐานเดียวกับยอดขาย

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) =>
  api()
    .post(url)
    .set(authHeader(token))
    .send(body ?? {});

/** ปัดเป็นสตางค์ — ยอดใน API เป็นบาททศนิยม 2 ตำแหน่ง */
const baht = (value) => Math.round(value * 100) / 100;

let waiter;
let cashier;
let manager;
let simpleMenu;

before(async () => {
  waiter = await login('waiter1', 'waiter123');
  cashier = await login('cashier', 'cashier123');
  manager = await login('manager', 'manager123');
  const menu = await get('/api/v1/menu-items?availableOnly=true&limit=200', waiter.token);
  simpleMenu = menu.body.data.filter(
    (item) =>
      !item.soldByWeight &&
      !item.optionGroups.some((group) => group.isRequired) &&
      item.price >= 60,
  );
  assert.ok(simpleMenu.length > 0, 'seed ต้องมีเมนูธรรมดาราคาอย่างน้อย 60 บาท');
});

const openDineIn = async () => {
  const table = (await get('/api/v1/tables?status=available', waiter.token)).body.data[0];
  const res = await post('/api/v1/orders', waiter.token, {
    type: 'dine_in',
    tableId: table.id,
    guestCount: 1,
    items: [{ menuItemId: simpleMenu[0].id, quantity: 1, optionIds: [] }],
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

const refund = async (paymentId, amount) => {
  const res = await post(`/api/v1/payments/${paymentId}/refund`, manager.token, {
    amount,
    reason: 'คืนเงินระหว่างทดสอบรายงาน',
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data;
};

/** ตัวเลขที่ต้องตรงกันในทั้ง 3 endpoint: ยอดขายสุทธิ ยอดคืน และยอด/จำนวนต่อช่องทาง */
const snapshot = async () => {
  const shift = (await get('/api/v1/shifts/current', manager.token)).body.data;
  assert.ok(shift, 'seed เปิดกะไว้ให้');
  const reports = {
    summary: await get('/api/v1/reports/summary', manager.token),
    byDate: await get('/api/v1/reports/z-report/by-date', manager.token),
    byShift: await get(`/api/v1/reports/z-report/by-shift/${shift.id}`, manager.token),
  };
  return Object.fromEntries(
    Object.entries(reports).map(([name, res]) => {
      assert.equal(res.status, 200, `${name}: ${JSON.stringify(res.body)}`);
      const data = res.body.data;
      const method = (key) => data.paymentMethods.find((row) => row.method === key);
      return [
        name,
        {
          orderCount: data.orderCount,
          netSales: data.netSales,
          refundTotal: data.refundTotal,
          cash: method('cash') ?? { count: 0, amount: 0 },
          card: method('card') ?? { count: 0, amount: 0 },
        },
      ];
    }),
  );
};

const assertDelta = (beforeAll, afterAll, expected) => {
  for (const name of Object.keys(beforeAll)) {
    const b = beforeAll[name];
    const a = afterAll[name];
    const delta = {
      orderCount: a.orderCount - b.orderCount,
      netSales: baht(a.netSales - b.netSales),
      refundTotal: baht(a.refundTotal - b.refundTotal),
      cashCount: a.cash.count - b.cash.count,
      cashAmount: baht(a.cash.amount - b.cash.amount),
      cardCount: a.card.count - b.card.count,
      cardAmount: baht(a.card.amount - b.card.amount),
    };
    assert.deepEqual(delta, expected, name);
  }
};

test('คืนเงินตอนบิลยังเปิดแล้วเก็บใหม่จนครบ → ยอดขายสุทธิเท่ายอดบิล ไม่หักยอดคืนซ้ำ ในทั้ง 3 รายงาน', async () => {
  const before = await snapshot();
  const order = await openDineIn();
  const first = await pay(order, 'cash', 50);
  await refund(first.payment.id, 50);
  const second = await pay(order, 'cash', order.total);
  assert.equal(second.isFullyPaid, true);

  assertDelta(before, await snapshot(), {
    orderCount: 1,
    netSales: order.total,
    refundTotal: 0,
    // payment แรกถูกคืนครบก่อนบิลปิด จึงไม่ใช่เงินที่ร้านเก็บไว้ เหลือ payment ที่สองรายการเดียว
    cashCount: 1,
    cashAmount: order.total,
    cardCount: 0,
    cardAmount: 0,
  });
});

test('รับเงินบางส่วน คืนครบ แล้วยกเลิกบิล → ยอดขาย ยอดคืน และช่องทางชำระเงินไม่เปลี่ยน ในทั้ง 3 รายงาน', async () => {
  const before = await snapshot();
  const order = await openDineIn();
  const paid = await pay(order, 'card', 50);
  await refund(paid.payment.id, 50);
  const cancelled = await post(`/api/v1/orders/${order.id}/cancel`, manager.token, {
    reason: 'ลูกค้าเดินออกไป',
  });
  assert.equal(cancelled.status, 200, JSON.stringify(cancelled.body));

  assertDelta(before, await snapshot(), {
    orderCount: 0,
    netSales: 0,
    refundTotal: 0,
    cashCount: 0,
    cashAmount: 0,
    cardCount: 0,
    cardAmount: 0,
  });
});

test('คืนบางส่วนก่อนปิดบิล แล้วคืนอีกหลังปิดบิล → หักเฉพาะส่วนที่คืนหลังปิด ในทั้ง 3 รายงาน', async () => {
  const before = await snapshot();
  const order = await openDineIn();
  const first = await pay(order, 'cash', 50);
  await refund(first.payment.id, 30);
  const second = await pay(order, 'cash', baht(order.total - 20));
  assert.equal(second.isFullyPaid, true);
  // หลังปิดบิล คืน 10 จาก payment แรก (คืนได้อีก 20) — นี่คือการคืนสินค้า/เงินจริงที่ลดยอดขาย
  await refund(first.payment.id, 10);

  assertDelta(before, await snapshot(), {
    orderCount: 1,
    netSales: baht(order.total - 10),
    refundTotal: 10,
    // ช่องทางชำระเงินคือเงินที่เก็บไว้ตอนบิลปิด (50 − 30 ที่คืนก่อนปิด + ยอดที่เก็บเพิ่ม) = ยอดบิล
    cashCount: 2,
    cashAmount: order.total,
    cardCount: 0,
    cardAmount: 0,
  });
});
