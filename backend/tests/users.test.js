// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

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

test('PATCH /users/:id — แอดมินเปลี่ยนบทบาท/ปิดใช้งานบัญชีตัวเองไม่ได้ แต่แก้ชื่อตัวเองได้', async () => {
  const admin = await login('admin', 'admin123');
  const me = await get('/api/v1/auth/me', admin.token);
  const url = `/api/v1/users/${me.body.data.id}`;

  const demote = await patch(url, admin.token, { role: 'waiter' });
  assert.equal(demote.status, 400);

  const deactivate = await patch(url, admin.token, { isActive: false });
  assert.equal(deactivate.status, 400);

  const rename = await patch(url, admin.token, { name: me.body.data.name });
  assert.equal(rename.status, 200);

  const still = await get('/api/v1/auth/me', admin.token);
  assert.equal(still.body.data.role, 'admin');
  assert.equal(still.body.data.isActive, true);
});

// ป้องกัน privilege escalation — ดูรายงาน security review (Vuln 2/3): manager ห้ามยกระดับ
// ตัวเอง/คนอื่นเป็น admin และห้ามแตะบัญชี admin เลย (สร้าง/แก้ไข/ตั้งรหัสผ่านใหม่)
test('POST /users — ผู้จัดการสร้างบัญชี admin ใหม่ไม่ได้ (กัน privilege escalation)', async () => {
  const { token } = await login('manager', 'manager123');

  const res = await post('/api/v1/users', token, {
    name: 'ไม่ควรเป็น admin ได้',
    username: uniqueUsername('newadmin'),
    password: 'test1234',
    role: 'admin',
  });

  assert.equal(res.status, 403);
});

test('PATCH /users/:id — ผู้จัดการเลื่อนตัวเองเป็น admin ไม่ได้', async () => {
  const manager = await login('manager', 'manager123');
  const me = await get('/api/v1/auth/me', manager.token);

  const res = await patch(`/api/v1/users/${me.body.data.id}`, manager.token, {
    role: 'admin',
  });

  assert.equal(res.status, 403);
});

test('PATCH /users/:id — ผู้จัดการแก้ไขบัญชี admin คนอื่นไม่ได้ แม้จะไม่แตะ role', async () => {
  const manager = await login('manager', 'manager123');
  const admin = await login('admin', 'admin123');
  const adminMe = await get('/api/v1/auth/me', admin.token);

  const res = await patch(`/api/v1/users/${adminMe.body.data.id}`, manager.token, {
    name: 'พยายามแก้ชื่อ admin',
  });

  assert.equal(res.status, 403);
});

test('POST /users/:id/reset-password — ผู้จัดการรีเซ็ตรหัสผ่านของ admin คนอื่นไม่ได้', async () => {
  const manager = await login('manager', 'manager123');
  const admin = await login('admin', 'admin123');
  const adminMe = await get('/api/v1/auth/me', admin.token);

  const res = await post(`/api/v1/users/${adminMe.body.data.id}/reset-password`, manager.token, {
    password: 'takeover123',
  });

  assert.equal(res.status, 403);
});

test('admin ยังสร้าง/แก้ไข/รีเซ็ตรหัสผ่านบัญชี admin คนอื่นได้ตามปกติ', async () => {
  const { token } = await login('admin', 'admin123');

  const created = await post('/api/v1/users', token, {
    name: 'แอดมินสำรอง',
    username: uniqueUsername('admin2'),
    password: 'test1234',
    role: 'admin',
  });
  assert.equal(created.status, 201);
  assert.equal(created.body.data.role, 'admin');

  const patched = await patch(`/api/v1/users/${created.body.data.id}`, token, {
    name: 'แอดมินสำรอง (แก้ชื่อ)',
  });
  assert.equal(patched.status, 200);

  const reset = await post(`/api/v1/users/${created.body.data.id}/reset-password`, token, {
    password: 'newpassword2',
  });
  assert.equal(reset.status, 200);
});

// เช็คสถานะบัญชีจาก DB ทุก request แทนที่จะเชื่อ token เก่าเฉยๆ — ดูรายงาน security review
// (Vuln 5): token ที่ออกไปก่อนถูกปิดใช้งาน/เปลี่ยน role ต้องใช้ต่อไม่ได้ทันที ไม่ต้องรอหมดอายุ
test('token เก่าใช้ต่อไม่ได้ทันทีหลังบัญชีถูกปิดใช้งาน (ไม่ต้องรอ token หมดอายุ)', async () => {
  const admin = await login('admin', 'admin123');
  const created = await post('/api/v1/users', admin.token, {
    name: 'จะถูกปิดใช้งานระหว่างมี token ค้าง',
    username: uniqueUsername('deactlive'),
    password: 'test1234',
    role: 'cashier',
  });

  const staff = await login(created.body.data.username, 'test1234');
  const before = await get('/api/v1/auth/me', staff.token);
  assert.equal(before.status, 200);

  await patch(`/api/v1/users/${created.body.data.id}`, admin.token, { isActive: false });

  const after = await get('/api/v1/auth/me', staff.token);
  assert.equal(after.status, 401);
});

test('token เก่าใช้สิทธิ์เดิมต่อไม่ได้หลังถูกเปลี่ยน role (สิทธิ์ใหม่มีผลทันทีจาก DB)', async () => {
  const admin = await login('admin', 'admin123');
  const created = await post('/api/v1/users', admin.token, {
    name: 'จะถูกลด role ระหว่างมี token ค้าง',
    username: uniqueUsername('demote'),
    password: 'test1234',
    role: 'manager',
  });

  const manager = await login(created.body.data.username, 'test1234');
  const beforeDemote = await post('/api/v1/users', manager.token, {
    name: 'สร้างได้ตอนยังเป็น manager',
    username: uniqueUsername('okmgr'),
    password: 'test1234',
    role: 'waiter',
  });
  assert.equal(beforeDemote.status, 201);

  await patch(`/api/v1/users/${created.body.data.id}`, admin.token, { role: 'waiter' });

  const afterDemote = await post('/api/v1/users', manager.token, {
    name: 'ไม่ควรสร้างได้แล้วหลังลด role',
    username: uniqueUsername('nomore'),
    password: 'test1234',
    role: 'waiter',
  });
  assert.equal(afterDemote.status, 403);
});
