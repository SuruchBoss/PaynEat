import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) => api().post(url).set(authHeader(token)).send(body);
const patch = (url, token, body) => api().patch(url).set(authHeader(token)).send(body);
const del = (url, token) => api().delete(url).set(authHeader(token));

// ชื่อโต๊ะจำกัดไว้ที่ 20 ตัวอักษร (ดู table.schema.js) จึงใช้แค่ตัวเลขท้าย timestamp
const uniqueName = (prefix) => `${prefix}${Date.now().toString().slice(-8)}`;

test('POST /tables — สร้างโต๊ะใหม่ได้ สถานะเริ่มต้นเป็นว่าง', async () => {
  const { token } = await login('admin', 'admin123');

  const res = await post('/api/v1/tables', token, { name: uniqueName('T'), seats: 4 });

  assert.equal(res.status, 201);
  assert.equal(res.body.data.status, 'available');
});

test('POST /tables — ชื่อโต๊ะซ้ำต้องได้ 409', async () => {
  const { token } = await login('admin', 'admin123');
  const name = uniqueName('DUP');
  await post('/api/v1/tables', token, { name });

  const res = await post('/api/v1/tables', token, { name });

  assert.equal(res.status, 409);
});

test('POST /tables — พนักงานเสิร์ฟสร้างโต๊ะไม่ได้ (RBAC 403)', async () => {
  const { token } = await login('waiter1', 'waiter123');

  const res = await post('/api/v1/tables', token, { name: uniqueName('X') });

  assert.equal(res.status, 403);
});

test('PATCH /tables/:id — เปลี่ยนชื่อเป็นชื่อที่โต๊ะอื่นใช้อยู่แล้วต้องได้ 409', async () => {
  const { token } = await login('admin', 'admin123');
  const nameA = uniqueName('A');
  const nameB = uniqueName('B');
  await post('/api/v1/tables', token, { name: nameA });
  const tableB = await post('/api/v1/tables', token, { name: nameB });

  const res = await patch(`/api/v1/tables/${tableB.body.data.id}`, token, { name: nameA });

  assert.equal(res.status, 409);
});

test('PATCH /tables/:id — เปลี่ยนชื่อเป็นชื่อเดิมของตัวเองไม่ควรถูกมองว่าซ้ำ', async () => {
  const { token } = await login('admin', 'admin123');
  const name = uniqueName('SELF');
  const table = await post('/api/v1/tables', token, { name });

  const res = await patch(`/api/v1/tables/${table.body.data.id}`, token, {
    name,
    seats: 6,
  });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.seats, 6);
});

test('PATCH /tables/:id/status — พนักงานเสิร์ฟเปลี่ยนสถานะโต๊ะได้เอง (ไม่ต้องรอผู้จัดการ)', async () => {
  const admin = await login('admin', 'admin123');
  const table = await post('/api/v1/tables', admin.token, { name: uniqueName('S') });

  const waiter = await login('waiter1', 'waiter123');
  const res = await patch(`/api/v1/tables/${table.body.data.id}/status`, waiter.token, {
    status: 'reserved',
  });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.status, 'reserved');
});

test('PATCH /tables/:id/status — ตั้งเป็นว่างไม่ได้ถ้ายังมีออเดอร์เปิดอยู่', async () => {
  const admin = await login('admin', 'admin123');
  const table = await post('/api/v1/tables', admin.token, { name: uniqueName('OPEN') });

  const waiter = await login('waiter1', 'waiter123');
  const menuRes = await get('/api/v1/menu-items?availableOnly=true&limit=200', waiter.token);
  const menuItem = menuRes.body.data[0];
  assert.ok(menuItem, 'ต้องมีเมนูที่ขายอยู่อย่างน้อย 1 รายการสำหรับเทสต์นี้');

  await post('/api/v1/orders', waiter.token, {
    type: 'dine_in',
    tableId: table.body.data.id,
    guestCount: 1,
    items: [{ menuItemId: menuItem.id, quantity: 1, optionIds: [] }],
  });

  const res = await patch(`/api/v1/tables/${table.body.data.id}/status`, waiter.token, {
    status: 'available',
  });

  assert.equal(res.status, 409);
});

test('DELETE /tables/:id — ลบไม่ได้ถ้ายังมีออเดอร์เปิดอยู่ ลบได้ปกติถ้าไม่มี', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');

  const busyTable = await post('/api/v1/tables', admin.token, { name: uniqueName('BUSY') });
  const menuRes = await get('/api/v1/menu-items?availableOnly=true&limit=200', waiter.token);
  const menuItem = menuRes.body.data[0];
  await post('/api/v1/orders', waiter.token, {
    type: 'dine_in',
    tableId: busyTable.body.data.id,
    guestCount: 1,
    items: [{ menuItemId: menuItem.id, quantity: 1, optionIds: [] }],
  });

  const blocked = await del(`/api/v1/tables/${busyTable.body.data.id}`, admin.token);
  assert.equal(blocked.status, 409);

  const freeTable = await post('/api/v1/tables', admin.token, { name: uniqueName('FREE') });
  const allowed = await del(`/api/v1/tables/${freeTable.body.data.id}`, admin.token);
  assert.equal(allowed.status, 204);
});

test('GET /tables/zones — คืนรายชื่อโซนที่มีอยู่จริง', async () => {
  const { token } = await login('admin', 'admin123');
  const zoneName = uniqueName('โซน');
  await post('/api/v1/tables', token, { name: uniqueName('Z'), zone: zoneName });

  const res = await get('/api/v1/tables/zones', token);

  assert.equal(res.status, 200);
  assert.ok(res.body.data.includes(zoneName));
});
