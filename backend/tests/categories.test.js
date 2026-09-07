import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) => api().post(url).set(authHeader(token)).send(body);
const patch = (url, token, body) => api().patch(url).set(authHeader(token)).send(body);
const del = (url, token) => api().delete(url).set(authHeader(token));

const uniqueName = (prefix) => `${prefix}${Date.now().toString().slice(-8)}`;

test('POST /categories — สร้างหมวดหมู่ใหม่ได้', async () => {
  const { token } = await login('admin', 'admin123');

  const res = await post('/api/v1/categories', token, { name: uniqueName('CAT') });

  assert.equal(res.status, 201);
  assert.equal(res.body.data.isActive, true);
});

test('POST /categories — พนักงานเสิร์ฟสร้างหมวดหมู่ไม่ได้ (RBAC 403)', async () => {
  const { token } = await login('waiter1', 'waiter123');

  const res = await post('/api/v1/categories', token, { name: uniqueName('X') });

  assert.equal(res.status, 403);
});

test('PATCH /categories/:id — แก้ไขชื่อได้', async () => {
  const { token } = await login('admin', 'admin123');
  const created = await post('/api/v1/categories', token, { name: uniqueName('OLD') });

  const res = await patch(`/api/v1/categories/${created.body.data.id}`, token, {
    name: 'ชื่อใหม่',
  });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.name, 'ชื่อใหม่');
});

test('PATCH /categories/:id — หมวดหมู่ที่ไม่มีอยู่จริงต้องได้ 404', async () => {
  const { token } = await login('admin', 'admin123');

  const res = await patch('/api/v1/categories/999999', token, { name: 'ไม่มีจริง' });

  assert.equal(res.status, 404);
});

test('DELETE /categories/:id — ลบไม่ได้ถ้ายังมีเมนูอยู่ในหมวดหมู่', async () => {
  const { token } = await login('admin', 'admin123');
  const category = await post('/api/v1/categories', token, { name: uniqueName('HASITEM') });
  await post('/api/v1/menu-items', token, {
    categoryId: category.body.data.id,
    name: 'เมนูในหมวดนี้',
    price: 40,
  });

  const res = await del(`/api/v1/categories/${category.body.data.id}`, token);

  assert.equal(res.status, 409);
});

test('DELETE /categories/:id — ลบได้ปกติถ้าไม่มีเมนูอยู่ในหมวดหมู่', async () => {
  const { token } = await login('admin', 'admin123');
  const category = await post('/api/v1/categories', token, { name: uniqueName('EMPTY') });

  const res = await del(`/api/v1/categories/${category.body.data.id}`, token);

  assert.equal(res.status, 204);
});

test('GET /categories — เห็นจำนวนเมนูรวมของแต่ละหมวดหมู่ (itemCount)', async () => {
  const { token } = await login('admin', 'admin123');
  const category = await post('/api/v1/categories', token, { name: uniqueName('COUNT') });
  await post('/api/v1/menu-items', token, {
    categoryId: category.body.data.id,
    name: 'เมนู1',
    price: 10,
  });
  await post('/api/v1/menu-items', token, {
    categoryId: category.body.data.id,
    name: 'เมนู2',
    price: 20,
  });

  const res = await get('/api/v1/categories', token);

  assert.equal(res.status, 200);
  const found = res.body.data.find((row) => row.id === category.body.data.id);
  assert.equal(found.itemCount, 2);
});
