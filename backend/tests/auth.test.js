import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

after(cleanup);

test('POST /auth/login — ล็อกอินสำเร็จได้ token และข้อมูลผู้ใช้', async () => {
  const res = await api()
    .post('/api/v1/auth/login')
    .send({ username: 'admin', password: 'admin123' });

  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.ok(res.body.data.token);
  assert.equal(res.body.data.user.username, 'admin');
  assert.equal(res.body.data.user.role, 'admin');
  assert.equal(res.body.data.user.password, undefined, 'ต้องไม่ส่งรหัสผ่านกลับไป');
});

test('POST /auth/login — รหัสผ่านผิดต้องได้ 401', async () => {
  const res = await api().post('/api/v1/auth/login').send({ username: 'admin', password: 'wrong' });
  assert.equal(res.status, 401);
  assert.equal(res.body.success, false);
});

test('POST /auth/login — ข้อมูลไม่ครบต้องได้ 422 พร้อมรายละเอียด', async () => {
  const res = await api().post('/api/v1/auth/login').send({ username: 'admin' });
  assert.equal(res.status, 422);
  assert.equal(res.body.error.code, 'VALIDATION_ERROR');
  assert.ok(Array.isArray(res.body.error.details));
});

test('GET /auth/me — ต้องมี token ถึงเข้าถึงได้', async () => {
  const unauthorized = await api().get('/api/v1/auth/me');
  assert.equal(unauthorized.status, 401);

  const { token } = await login('waiter1', 'waiter123');
  const res = await api().get('/api/v1/auth/me').set(authHeader(token));
  assert.equal(res.status, 200);
  assert.equal(res.body.data.role, 'waiter');
});

test('RBAC — พนักงานเสิร์ฟเข้าถึงรายชื่อพนักงานไม่ได้ (403)', async () => {
  const { token } = await login('waiter1', 'waiter123');
  const res = await api().get('/api/v1/users').set(authHeader(token));
  assert.equal(res.status, 403);
});

test('RBAC — แอดมินเข้าถึงรายชื่อพนักงานได้', async () => {
  const { token } = await login('admin', 'admin123');
  const res = await api().get('/api/v1/users').set(authHeader(token));
  assert.equal(res.status, 200);
  assert.ok(res.body.data.length >= 5);
});
