import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) => api().post(url).set(authHeader(token)).send(body);
const patch = (url, token, body) => api().patch(url).set(authHeader(token)).send(body);

/** เปิดออเดอร์ 1 ใบที่โต๊ะว่าง พร้อมเมนู `count` รายการ (คนละเมนู คนละราคา) คืนออเดอร์ + โต๊ะ */
const openOrderWithItems = async (waiterToken, count = 2) => {
  const tablesRes = await get('/api/v1/tables?status=available', waiterToken);
  assert.ok(tablesRes.body.data.length >= 1, 'ต้องมีโต๊ะว่างอย่างน้อย 1 โต๊ะสำหรับเทสต์นี้');
  const table = tablesRes.body.data[0];

  const menuRes = await get('/api/v1/menu-items?availableOnly=true&limit=200', waiterToken);
  // เลี่ยงเมนูที่มีกลุ่มตัวเลือกบังคับ (เช่น "ระดับความเผ็ด") เพื่อไม่ต้องส่ง optionIds ให้ครบเงื่อนไข
  const simpleItems = menuRes.body.data.filter(
    (item) => !item.optionGroups.some((group) => group.isRequired),
  );
  assert.ok(simpleItems.length >= count, `ต้องมีเมนูไม่มีตัวเลือกบังคับอย่างน้อย ${count} รายการ`);
  const menuItems = simpleItems.slice(0, count);

  const res = await post('/api/v1/orders', waiterToken, {
    type: 'dine_in',
    tableId: table.id,
    guestCount: 2,
    items: menuItems.map((menuItem) => ({ menuItemId: menuItem.id, quantity: 1, optionIds: [] })),
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return { order: res.body.data, table };
};

const anotherAvailableTable = async (token, excludeTableId) => {
  const res = await get('/api/v1/tables?status=available', token);
  const table = res.body.data.find((row) => row.id !== excludeTableId);
  assert.ok(table, 'ต้องมีโต๊ะว่างอีกโต๊ะสำหรับเทสต์นี้');
  return table;
};

test('PATCH /orders/:id/move-table — ย้ายโต๊ะสำเร็จ โต๊ะเก่าว่างคืน โต๊ะใหม่ไม่ว่าง', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const { order, table } = await openOrderWithItems(waiter.token, 1);
  const target = await anotherAvailableTable(waiter.token, table.id);

  const res = await patch(`/api/v1/orders/${order.id}/move-table`, waiter.token, {
    tableId: target.id,
  });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.tableId, target.id);

  const oldTableRes = await get(`/api/v1/tables/${table.id}`, waiter.token);
  assert.equal(oldTableRes.body.data.status, 'available');
  const newTableRes = await get(`/api/v1/tables/${target.id}`, waiter.token);
  assert.equal(newTableRes.body.data.status, 'occupied');
});

test('PATCH /orders/:id/move-table — โต๊ะปลายทางมีออเดอร์เปิดอยู่แล้วต้องได้ 409', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const { order: orderA } = await openOrderWithItems(waiter.token, 1);
  const { order: orderB, table: tableB } = await openOrderWithItems(waiter.token, 1);

  const res = await patch(`/api/v1/orders/${orderA.id}/move-table`, waiter.token, {
    tableId: tableB.id,
  });

  assert.equal(res.status, 409);
  assert.equal(orderB.tableId, tableB.id);
});

test('POST /orders/:id/merge — รวมบิลสำเร็จ ยอดรวมเข้าออเดอร์ปลายทาง ต้นทางถูกยกเลิกและโต๊ะว่างคืน', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const { order: target } = await openOrderWithItems(waiter.token, 1);
  const { order: source, table: sourceTable } = await openOrderWithItems(waiter.token, 1);

  const res = await post(`/api/v1/orders/${target.id}/merge`, waiter.token, {
    sourceOrderId: source.id,
  });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.items.length, target.items.length + source.items.length);
  assert.ok(
    Math.abs(res.body.data.total - (target.total + source.total)) < 0.01,
    'ยอดรวมหลังรวมบิลต้องเท่ากับยอดของสองออเดอร์บวกกัน',
  );

  const sourceRes = await get(`/api/v1/orders/${source.id}`, waiter.token);
  assert.equal(sourceRes.body.data.status, 'cancelled');

  const tableRes = await get(`/api/v1/tables/${sourceTable.id}`, waiter.token);
  assert.equal(tableRes.body.data.status, 'available');
});

test('POST /orders/:id/merge — รวมกับตัวเองต้องได้ 400', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const { order } = await openOrderWithItems(waiter.token, 1);

  const res = await post(`/api/v1/orders/${order.id}/merge`, waiter.token, {
    sourceOrderId: order.id,
  });

  assert.equal(res.status, 400);
});

test('POST /payments/order/:id/split-preview — คำนวณยอดตามสัดส่วนของรายการที่เลือก', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { order } = await openOrderWithItems(waiter.token, 2);
  const [itemA] = order.items;

  const res = await post(`/api/v1/payments/order/${order.id}/split-preview`, cashier.token, {
    itemIds: [itemA.id],
  });

  assert.equal(res.status, 200);
  assert.ok(res.body.data.total > 0);
  assert.ok(res.body.data.total < order.total, 'เลือกแค่บางรายการยอดต้องน้อยกว่ายอดเต็มบิล');
  assert.equal(res.body.data.isLastBatch, false);
});

test('POST /payments (itemIds) — จ่ายทีละรายการจนครบ ปิดออเดอร์และคืนโต๊ะในรอบสุดท้าย', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { order, table } = await openOrderWithItems(waiter.token, 2);
  const [itemA, itemB] = order.items;

  const first = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'qr',
    itemIds: [itemA.id],
  });
  assert.equal(first.status, 201);
  assert.equal(first.body.data.isFullyPaid, false);
  assert.equal(first.body.data.order.status, 'open');
  const itemAAfter = first.body.data.order.items.find((row) => row.id === itemA.id);
  assert.equal(itemAAfter.isPaid, true);

  const second = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    itemIds: [itemB.id],
  });
  assert.equal(second.status, 201);
  assert.equal(second.body.data.isFullyPaid, true);
  assert.equal(second.body.data.order.status, 'paid');

  const tableRes = await get(`/api/v1/tables/${table.id}`, cashier.token);
  assert.equal(tableRes.body.data.status, 'available');
});

test('POST /payments (itemIds) — เลือกรายการที่จ่ายไปแล้วซ้ำต้องได้ 409', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { order } = await openOrderWithItems(waiter.token, 2);
  const [itemA] = order.items;

  await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'qr',
    itemIds: [itemA.id],
  });

  const res = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'qr',
    itemIds: [itemA.id],
  });

  assert.equal(res.status, 409);
});
