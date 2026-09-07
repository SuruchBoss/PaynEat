import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) => api().post(url).set(authHeader(token)).send(body);
const patch = (url, token, body) => api().patch(url).set(authHeader(token)).send(body);
const del = (url, token) => api().delete(url).set(authHeader(token));

const uniqueUsername = (prefix) => `${prefix}${Date.now().toString().slice(-8)}`;

test('POST /users — ผู้จัดการสร้างพนักงานใหม่ได้ ไม่ส่งรหัสผ่านกลับมา', async () => {
  const { token } = await login('manager', 'manager123');

  const res = await post('/api/v1/users', token, {
    name: 'พนักงานทดสอบ',
    username: uniqueUsername('staff'),
    password: 'test1234',
    role: 'waiter',
  });

  assert.equal(res.status, 201);
  assert.equal(res.body.data.role, 'waiter');
  assert.equal(res.body.data.password, undefined);
  assert.equal(res.body.data.passwordHash, undefined);
});

test('POST /users — username ซ้ำต้องได้ 409', async () => {
  const { token } = await login('manager', 'manager123');
  const username = uniqueUsername('dup');
  await post('/api/v1/users', token, {
    name: 'คนแรก',
    username,
    password: 'test1234',
    role: 'waiter',
  });

  const res = await post('/api/v1/users', token, {
    name: 'คนที่สอง',
    username,
    password: 'test1234',
    role: 'cashier',
  });

  assert.equal(res.status, 409);
});

test('POST /users — พนักงานเสิร์ฟสร้างพนักงานใหม่ไม่ได้ (RBAC 403)', async () => {
  const { token } = await login('waiter1', 'waiter123');

  const res = await post('/api/v1/users', token, {
    name: 'ไม่ควรสร้างได้',
    username: uniqueUsername('nope'),
    password: 'test1234',
    role: 'waiter',
  });

  assert.equal(res.status, 403);
});

test('PATCH /users/:id — ปิดการใช้งานบัญชีได้', async () => {
  const { token } = await login('manager', 'manager123');
  const created = await post('/api/v1/users', token, {
    name: 'จะถูกปิดใช้งาน',
    username: uniqueUsername('deact'),
    password: 'test1234',
    role: 'kitchen',
  });

  const res = await patch(`/api/v1/users/${created.body.data.id}`, token, {
    isActive: false,
  });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.isActive, false);
});

test('POST /users/:id/reset-password — เปลี่ยนรหัสผ่านแล้วล็อกอินด้วยรหัสใหม่ได้', async () => {
  const { token } = await login('admin', 'admin123');
  const created = await post('/api/v1/users', token, {
    name: 'รีเซ็ตรหัสผ่าน',
    username: uniqueUsername('resetpw'),
    password: 'oldpassword',
    role: 'cashier',
  });

  const reset = await post(`/api/v1/users/${created.body.data.id}/reset-password`, token, {
    password: 'newpassword',
  });
  assert.equal(reset.status, 200);

  const loginRes = await login(created.body.data.username, 'newpassword');
  assert.ok(loginRes.token);
});

test('DELETE /users/:id — ผู้จัดการลบพนักงานไม่ได้ (สงวนไว้เฉพาะ admin)', async () => {
  const manager = await login('manager', 'manager123');
  const created = await post('/api/v1/users', manager.token, {
    name: 'จะลองลบ',
    username: uniqueUsername('nodel'),
    password: 'test1234',
    role: 'waiter',
  });

  const res = await del(`/api/v1/users/${created.body.data.id}`, manager.token);

  assert.equal(res.status, 403);
});

test('DELETE /users/:id — แอดมินลบพนักงานคนอื่นได้ แต่ลบตัวเองไม่ได้', async () => {
  const admin = await login('admin', 'admin123');
  const created = await post('/api/v1/users', admin.token, {
    name: 'จะถูกลบ',
    username: uniqueUsername('willdel'),
    password: 'test1234',
    role: 'waiter',
  });

  const deleteOther = await del(`/api/v1/users/${created.body.data.id}`, admin.token);
  assert.equal(deleteOther.status, 204);

  const me = await get('/api/v1/auth/me', admin.token);
  const deleteSelf = await del(`/api/v1/users/${me.body.data.id}`, admin.token);
  assert.equal(deleteSelf.status, 400);
});
