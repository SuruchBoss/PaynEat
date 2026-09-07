import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const patch = (url, token, body) => api().patch(url).set(authHeader(token)).send(body);

test('GET /settings — พนักงานทุกบทบาทอ่านค่าตั้งค่าร้านได้', async () => {
  const { token } = await login('waiter1', 'waiter123');

  const res = await get('/api/v1/settings', token);

  assert.equal(res.status, 200);
  assert.ok(res.body.data.storeName);
  assert.equal(typeof res.body.data.vatRate, 'number');
  assert.equal(typeof res.body.data.vatIncluded, 'boolean');
});

test('PATCH /settings — ผู้จัดการแก้ค่าตั้งค่าได้ และค่าที่ไม่ส่งมาไม่ถูกแตะ', async () => {
  const { token } = await login('manager', 'manager123');
  const before = await get('/api/v1/settings', token);

  const res = await patch('/api/v1/settings', token, { storeName: 'ร้านทดสอบใหม่' });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.storeName, 'ร้านทดสอบใหม่');
  assert.equal(res.body.data.vatRate, before.body.data.vatRate);
  assert.equal(res.body.data.currency, before.body.data.currency);
});

test('PATCH /settings — แก้ vatRate และ vatIncluded (ค่าตัวเลข/บูลีน) แล้วอ่านกลับมาต้องตรง', async () => {
  const { token } = await login('admin', 'admin123');

  const res = await patch('/api/v1/settings', token, {
    vatRate: 0.08,
    vatIncluded: true,
  });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.vatRate, 0.08);
  assert.equal(res.body.data.vatIncluded, true);

  const after = await get('/api/v1/settings', token);
  assert.equal(after.body.data.vatRate, 0.08);
  assert.equal(after.body.data.vatIncluded, true);
});

test('PATCH /settings — พนักงานเสิร์ฟแก้ค่าตั้งค่าไม่ได้ (RBAC 403)', async () => {
  const { token } = await login('waiter1', 'waiter123');

  const res = await patch('/api/v1/settings', token, { storeName: 'ไม่ควรแก้ได้' });

  assert.equal(res.status, 403);
});

test('PATCH /settings — ค่านอกช่วงที่กำหนด (vatRate > 1) ต้องได้ 422', async () => {
  const { token } = await login('admin', 'admin123');

  const res = await patch('/api/v1/settings', token, { vatRate: 1.5 });

  assert.equal(res.status, 422);
});
