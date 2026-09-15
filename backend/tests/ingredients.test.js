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
const patch = (url, token, body) =>
  api()
    .patch(url)
    .set(authHeader(token))
    .send(body ?? {});
const del = (url, token) => api().delete(url).set(authHeader(token));

const createIngredient = async (token, overrides = {}) => {
  const res = await post('/api/v1/ingredients', token, {
    name: `วัตถุดิบทดสอบ-${Date.now()}-${Math.random()}`,
    unit: 'กรัม',
    currentStock: 1000,
    lowStockThreshold: 100,
    ...overrides,
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data;
};

test('POST /ingredients — สร้างวัตถุดิบใหม่ได้', async () => {
  const { token } = await login('admin', 'admin123');
  const ingredient = await createIngredient(token, { currentStock: 500, lowStockThreshold: 50 });

  assert.equal(ingredient.currentStock, 500);
  assert.equal(ingredient.lowStockThreshold, 50);
  assert.equal(ingredient.isLowStock, false);
});

test('POST /ingredients — พนักงานเสิร์ฟสร้างวัตถุดิบไม่ได้ (RBAC 403)', async () => {
  const { token } = await login('waiter1', 'waiter123');
  const res = await post('/api/v1/ingredients', token, {
    name: 'ไม่ควรสร้างได้',
    unit: 'กรัม',
  });
  assert.equal(res.status, 403);
});

test('POST /ingredients — ข้อมูลไม่ครบ (ไม่มีหน่วย) ต้องได้ 422', async () => {
  const { token } = await login('admin', 'admin123');
  const res = await post('/api/v1/ingredients', token, { name: 'ไม่มีหน่วยนับ' });
  assert.equal(res.status, 422);
  assert.equal(res.body.error.code, 'VALIDATION_ERROR');
});

test('PATCH /ingredients/:id — แก้ชื่อ/หน่วย/threshold ได้ แต่แก้ currentStock ตรง ๆ ไม่ได้', async () => {
  const { token } = await login('admin', 'admin123');
  const ingredient = await createIngredient(token);

  const res = await patch(`/api/v1/ingredients/${ingredient.id}`, token, {
    name: 'ชื่อใหม่',
    lowStockThreshold: 200,
    currentStock: 99999, // ไม่ใช่ field ที่ schema รู้จัก ต้องถูกเพิกเฉย ไม่ throw
  });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.name, 'ชื่อใหม่');
  assert.equal(res.body.data.lowStockThreshold, 200);
  assert.equal(res.body.data.currentStock, ingredient.currentStock); // ไม่เปลี่ยน
});

test('POST /ingredients/:id/adjust-stock — เติม/หักสต๊อกได้ และ isLowStock อัปเดตตาม', async () => {
  const { token } = await login('admin', 'admin123');
  const ingredient = await createIngredient(token, { currentStock: 100, lowStockThreshold: 50 });

  const restock = await post(`/api/v1/ingredients/${ingredient.id}/adjust-stock`, token, {
    delta: 50,
  });
  assert.equal(restock.status, 200);
  assert.equal(restock.body.data.currentStock, 150);
  assert.equal(restock.body.data.isLowStock, false);

  const deduct = await post(`/api/v1/ingredients/${ingredient.id}/adjust-stock`, token, {
    delta: -120,
  });
  assert.equal(deduct.status, 200);
  assert.equal(deduct.body.data.currentStock, 30);
  assert.equal(deduct.body.data.isLowStock, true); // 30 <= 50
});

test('POST /ingredients/:id/adjust-stock — delta เป็น 0 ต้องได้ 422', async () => {
  const { token } = await login('admin', 'admin123');
  const ingredient = await createIngredient(token);

  const res = await post(`/api/v1/ingredients/${ingredient.id}/adjust-stock`, token, {
    delta: 0,
  });
  assert.equal(res.status, 422);
});

test('GET /ingredients?lowStockOnly=true — คืนเฉพาะวัตถุดิบที่ต่ำกว่า/เท่ากับ threshold', async () => {
  const { token } = await login('admin', 'admin123');
  const low = await createIngredient(token, { currentStock: 5, lowStockThreshold: 10 });
  const normal = await createIngredient(token, { currentStock: 500, lowStockThreshold: 10 });

  const res = await get('/api/v1/ingredients?lowStockOnly=true', token);
  assert.equal(res.status, 200);
  const ids = res.body.data.map((row) => row.id);
  assert.ok(ids.includes(low.id));
  assert.ok(!ids.includes(normal.id));
});

test('DELETE /ingredients/:id — ลบไม่ได้ถ้ายังผูกกับเมนูอยู่', async () => {
  const { token } = await login('admin', 'admin123');
  const ingredient = await createIngredient(token);
  const categoryRes = await post('/api/v1/categories', token, {
    name: `หมวดทดสอบ-${Date.now()}`,
  });
  const menuItem = await post('/api/v1/menu-items', token, {
    categoryId: categoryRes.body.data.id,
    name: `เมนูผูกวัตถุดิบ-${Date.now()}`,
    price: 50,
    ingredients: [{ ingredientId: ingredient.id, qtyPerUnit: 10 }],
  });
  assert.equal(menuItem.status, 201);
  assert.equal(menuItem.body.data.ingredients.length, 1);
  assert.equal(menuItem.body.data.ingredients[0].ingredientId, ingredient.id);
  assert.equal(menuItem.body.data.ingredients[0].qtyPerUnit, 10);

  const res = await del(`/api/v1/ingredients/${ingredient.id}`, token);
  assert.equal(res.status, 409);
});

test('DELETE /ingredients/:id — ลบได้ปกติถ้าไม่มีเมนูผูกอยู่', async () => {
  const { token } = await login('admin', 'admin123');
  const ingredient = await createIngredient(token);

  const res = await del(`/api/v1/ingredients/${ingredient.id}`, token);
  assert.equal(res.status, 204);

  const detail = await get(`/api/v1/ingredients/${ingredient.id}`, token);
  assert.equal(detail.status, 404);
});

test('POST /menu-items — เลือกวัตถุดิบซ้ำกันในเมนูเดียวต้องได้ 422', async () => {
  const { token } = await login('admin', 'admin123');
  const ingredient = await createIngredient(token);
  const categoryRes = await post('/api/v1/categories', token, {
    name: `หมวดทดสอบ-${Date.now()}`,
  });

  const res = await post('/api/v1/menu-items', token, {
    categoryId: categoryRes.body.data.id,
    name: `เมนูวัตถุดิบซ้ำ-${Date.now()}`,
    price: 40,
    ingredients: [
      { ingredientId: ingredient.id, qtyPerUnit: 5 },
      { ingredientId: ingredient.id, qtyPerUnit: 10 },
    ],
  });
  assert.equal(res.status, 422);
});

test('POST /menu-items — ingredientId ที่ไม่มีอยู่จริงต้องได้ 400', async () => {
  const { token } = await login('admin', 'admin123');
  const categoryRes = await post('/api/v1/categories', token, {
    name: `หมวดทดสอบ-${Date.now()}`,
  });

  const res = await post('/api/v1/menu-items', token, {
    categoryId: categoryRes.body.data.id,
    name: `เมนูวัตถุดิบไม่มีจริง-${Date.now()}`,
    price: 40,
    ingredients: [{ ingredientId: 999999, qtyPerUnit: 5 }],
  });
  assert.equal(res.status, 400);
});
