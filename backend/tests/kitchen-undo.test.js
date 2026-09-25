import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

after(cleanup);

// จอครัวกดผิดต้องย้อนได้หนึ่งขั้น (DECISIONS #64) — แต่ served ย้อนไม่ได้ และห้ามกระโดดข้ามขั้น

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) => api().post(url).set(authHeader(token)).send(body);
const patch = (url, token, body) => api().patch(url).set(authHeader(token)).send(body);

const openOrder = async (token) => {
  const table = (await get('/api/v1/tables?status=available', token)).body.data[0];
  const menu = (await get('/api/v1/menu-items?availableOnly=true&limit=200', token)).body.data;
  const simple = menu.find(
    (item) => !item.soldByWeight && !item.optionGroups.some((group) => group.isRequired),
  );
  const res = await post('/api/v1/orders', token, {
    type: 'dine_in',
    tableId: table.id,
    guestCount: 2,
    items: [{ menuItemId: simple.id, quantity: 1, optionIds: [] }],
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  await post(`/api/v1/orders/${res.body.data.id}/send-to-kitchen`, token, {});
  return res.body.data;
};

test('ครัวย้อนสถานะได้ทีละขั้น: ready → cooking → pending แต่ served ย้อนไม่ได้', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const kitchen = await login('kitchen', 'kitchen123');
  const order = await openOrder(waiter.token);
  const itemId = order.items[0].id;
  const setStatus = (token, status) =>
    patch(`/api/v1/orders/${order.id}/items/${itemId}/status`, token, { status });
  const statusNow = async () =>
    (await get(`/api/v1/orders/${order.id}`, kitchen.token)).body.data.items[0].status;

  assert.equal((await setStatus(kitchen.token, 'cooking')).status, 200);
  assert.equal((await setStatus(kitchen.token, 'ready')).status, 200);

  // กด "ทำเสร็จแล้ว" ผิด → ย้อนกลับไปกำลังทำ แล้วย้อนอีกขั้นเป็นรอทำ
  assert.equal((await setStatus(kitchen.token, 'cooking')).status, 200);
  assert.equal(await statusNow(), 'cooking');
  assert.equal((await setStatus(kitchen.token, 'pending')).status, 200);
  assert.equal(await statusNow(), 'pending');

  // ย้อนจากรอทำไม่มีขั้นก่อนหน้า
  assert.equal((await setStatus(kitchen.token, 'pending')).status, 409);

  // เสิร์ฟแล้วย้อนไม่ได้ — ออเดอร์อาจขึ้นเสิร์ฟครบไปแล้ว
  assert.equal((await setStatus(waiter.token, 'ready')).status, 200);
  assert.equal((await setStatus(waiter.token, 'served')).status, 200);
  const back = await setStatus(kitchen.token, 'ready');
  assert.equal(back.status, 409);
  assert.equal(await statusNow(), 'served');
});
