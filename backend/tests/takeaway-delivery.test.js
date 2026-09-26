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

/** ดึงเมนู 1 อย่างที่เปิดขายอยู่ ใช้สร้างออเดอร์ทดสอบ */
const oneAvailableMenuItem = async (token) => {
  const res = await get('/api/v1/menu-items?availableOnly=true&limit=1', token);
  return res.body.data[0];
};

test('เลขคิวรับอาหาร — เฉพาะ takeaway, รันต่อเนื่อง, dine_in/delivery ไม่มี', async (t) => {
  const waiter = await login('waiter1', 'waiter123');

  let table;
  await t.test('เตรียมโต๊ะว่างไว้เปิดออเดอร์ dine_in', async () => {
    const res = await get('/api/v1/tables', waiter.token);
    table = res.body.data.find((row) => row.status === 'available');
    assert.ok(table, 'ต้องมีโต๊ะว่างอย่างน้อย 1 โต๊ะ');
  });

  await t.test('ออเดอร์ dine_in ไม่มีเลขคิว', async () => {
    const menuItem = await oneAvailableMenuItem(waiter.token);
    const res = await post('/api/v1/orders', waiter.token, {
      type: 'dine_in',
      tableId: table.id,
      items: [{ menuItemId: menuItem.id, quantity: 1 }],
    });
    assert.equal(res.status, 201);
    assert.equal(res.body.data.queueNumber, null);
  });

  await t.test('ออเดอร์ delivery ไม่มีเลขคิว (ไรเดอร์อ้างอิงจาก code แทน)', async () => {
    const menuItem = await oneAvailableMenuItem(waiter.token);
    const res = await post('/api/v1/orders', waiter.token, {
      type: 'delivery',
      items: [{ menuItemId: menuItem.id, quantity: 1 }],
    });
    assert.equal(res.status, 201);
    assert.equal(res.body.data.tableId, null);
    assert.equal(res.body.data.queueNumber, null);
  });

  await t.test('ออเดอร์ takeaway 3 ใบติดกัน ได้เลขคิวรันต่อเนื่อง', async () => {
    const menuItem = await oneAvailableMenuItem(waiter.token);
    const queueNumbers = [];
    for (let i = 0; i < 3; i += 1) {
      const res = await post('/api/v1/orders', waiter.token, {
        type: 'takeaway',
        items: [{ menuItemId: menuItem.id, quantity: 1 }],
      });
      assert.equal(res.status, 201);
      queueNumbers.push(res.body.data.queueNumber);
    }
    assert.deepEqual(queueNumbers, [queueNumbers[0], queueNumbers[0] + 1, queueNumbers[0] + 2]);
  });
});

test('คิวครัว (KDS) เห็นประเภทออเดอร์ของแต่ละรายการถูกต้อง', async (t) => {
  const waiter = await login('waiter1', 'waiter123');
  const kitchen = await login('kitchen', 'kitchen123');
  const menuItem = await oneAvailableMenuItem(waiter.token);

  let table;
  await t.test('เตรียมโต๊ะว่าง', async () => {
    const res = await get('/api/v1/tables', waiter.token);
    table = res.body.data.find((row) => row.status === 'available');
    assert.ok(table);
  });

  const orders = {};
  await t.test('เปิดออเดอร์ครบทั้ง 3 ประเภทแล้วส่งครัว', async () => {
    for (const type of ['dine_in', 'takeaway', 'delivery']) {
      const created = await post('/api/v1/orders', waiter.token, {
        type,
        tableId: type === 'dine_in' ? table.id : undefined,
        items: [{ menuItemId: menuItem.id, quantity: 1 }],
      });
      assert.equal(created.status, 201);
      orders[type] = created.body.data;
      const sent = await post(
        `/api/v1/orders/${created.body.data.id}/send-to-kitchen`,
        waiter.token,
      );
      assert.equal(sent.status, 200);
    }
  });

  await t.test('คิวครัวติด orderType ตรงกับที่เปิดไว้ทุกออเดอร์', async () => {
    const res = await get('/api/v1/orders/kitchen/queue', kitchen.token);
    assert.equal(res.status, 200);
    for (const type of ['dine_in', 'takeaway', 'delivery']) {
      const item = res.body.data.find((row) => row.orderCode === orders[type].code);
      assert.ok(item, `ต้องเห็นรายการของออเดอร์ type=${type} ในคิวครัว`);
      assert.equal(item.orderType, type);
    }
  });
});

test('เช็คบิล/ชำระเงินออเดอร์ takeaway ได้ตามปกติโดยไม่ต้องมีโต๊ะ', async (t) => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const menuItem = await oneAvailableMenuItem(waiter.token);

  let orderId;
  await t.test('เปิดออเดอร์กลับบ้านแล้วส่งครัว', async () => {
    const created = await post('/api/v1/orders', waiter.token, {
      type: 'takeaway',
      items: [{ menuItemId: menuItem.id, quantity: 2 }],
    });
    assert.equal(created.status, 201);
    orderId = created.body.data.id;
    const sent = await post(`/api/v1/orders/${orderId}/send-to-kitchen`, waiter.token);
    assert.equal(sent.status, 200);
  });

  await t.test('เก็บเงินเต็มจำนวนได้ปกติ ไม่ติด flow ที่บังคับเลือกโต๊ะ', async () => {
    const summary = await get(`/api/v1/payments/order/${orderId}/receipt`, cashier.token);
    assert.equal(summary.status, 200);
    assert.equal(summary.body.data.order.tableId, null);

    const order = await get(`/api/v1/orders/${orderId}`, cashier.token);
    const res = await post('/api/v1/payments', cashier.token, {
      orderId,
      method: 'cash',
      amount: order.body.data.total,
      received: order.body.data.total,
    });
    assert.equal(res.status, 201);
    assert.equal(res.body.data.isFullyPaid, true);
  });
});
