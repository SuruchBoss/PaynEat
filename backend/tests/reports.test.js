import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) => api().post(url).set(authHeader(token)).send(body);

/** เปิดออเดอร์ 1 ใบแล้วจ่ายเต็มจำนวนทันที ให้มีข้อมูลยอดขายจริงสำหรับทดสอบรายงาน */
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

const today = () => new Date().toISOString().slice(0, 10);

test('GET /reports/summary — ยอดขายวันนี้เพิ่มขึ้นตามจำนวนออเดอร์ที่จ่ายแล้ว', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const manager = await login('manager', 'manager123');

  const before = await get(`/api/v1/reports/summary?from=${today()}&to=${today()}`, manager.token);
  const beforeCount = before.body.data.orderCount;

  const { order } = await payOffOneOrder(waiter.token, cashier.token);

  const after = await get(`/api/v1/reports/summary?from=${today()}&to=${today()}`, manager.token);

  assert.equal(after.body.data.orderCount, beforeCount + 1);
  assert.ok(after.body.data.netSales >= order.total);
});

test('GET /reports/top-items — เมนูที่เพิ่งขายไปต้องติดอันดับด้วยจำนวนที่ถูกต้อง', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const manager = await login('manager', 'manager123');

  const { menuItem } = await payOffOneOrder(waiter.token, cashier.token, 3);

  const res = await get(
    `/api/v1/reports/top-items?from=${today()}&to=${today()}&limit=50`,
    manager.token,
  );

  assert.equal(res.status, 200);
  const found = res.body.data.find((row) => row.menuItemId === menuItem.id);
  assert.ok(found, 'เมนูที่เพิ่งขายไปต้องอยู่ใน top-items');
  assert.ok(found.quantity >= 3);
});

test('GET /reports/sales-by-day — มีแถวของวันนี้หลังจ่ายเงินสำเร็จ', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const manager = await login('manager', 'manager123');

  await payOffOneOrder(waiter.token, cashier.token);

  const res = await get(
    `/api/v1/reports/sales-by-day?from=${today()}&to=${today()}`,
    manager.token,
  );

  assert.equal(res.status, 200);
  const row = res.body.data.find((r) => r.day === today());
  assert.ok(row);
  assert.ok(row.orderCount >= 1);
});

test('GET /reports/dashboard — มียอดวันนี้ กราฟรายชั่วโมง และตัวนับสดครบ', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const manager = await login('manager', 'manager123');

  await payOffOneOrder(waiter.token, cashier.token);

  const res = await get('/api/v1/reports/dashboard', manager.token);

  assert.equal(res.status, 200);
  assert.ok(res.body.data.today);
  assert.ok(Array.isArray(res.body.data.hourly));
  assert.ok(Array.isArray(res.body.data.topItems));
  assert.equal(typeof res.body.data.live.totalTables, 'number');
});

test('GET /reports/summary — พนักงานเสิร์ฟดูรายงานไม่ได้ (RBAC 403)', async () => {
  const { token } = await login('waiter1', 'waiter123');

  const res = await get(`/api/v1/reports/summary?from=${today()}&to=${today()}`, token);

  assert.equal(res.status, 403);
});

test('GET /reports/summary — แคชเชียร์ดูรายงานได้ (อนุญาตเป็นกรณีพิเศษ)', async () => {
  const { token } = await login('cashier', 'cashier123');

  const res = await get(`/api/v1/reports/summary?from=${today()}&to=${today()}`, token);

  assert.equal(res.status, 200);
});
