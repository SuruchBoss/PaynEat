// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';
import { storeClock } from '../src/modules/settings/storeClock.js';

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

test('PATCH /settings — ตั้งเลขพร้อมเพย์ (promptPayId) แล้วอ่านกลับมาต้องตรง (ดู ticket 16)', async () => {
  const { token } = await login('admin', 'admin123');

  const res = await patch('/api/v1/settings', token, { promptPayId: '0812345678' });

  assert.equal(res.status, 200);
  assert.equal(res.body.data.promptPayId, '0812345678');

  const after = await get('/api/v1/settings', token);
  assert.equal(after.body.data.promptPayId, '0812345678');
});

test('PATCH /settings — ตั้งเขตเวลาของร้านได้ ค่าเริ่มต้น Asia/Bangkok และชื่อที่ไม่ใช่ IANA ได้ 400 (T03 #94)', async () => {
  const { token } = await login('manager', 'manager123');
  const before = await get('/api/v1/settings', token);
  assert.equal(before.body.data.timeZone, 'Asia/Bangkok');

  const saved = await patch('/api/v1/settings', token, { timeZone: 'asia/seoul' });
  assert.equal(saved.status, 200, JSON.stringify(saved.body));
  assert.equal(saved.body.data.timeZone, 'Asia/Seoul', 'เก็บเป็นตัวพิมพ์มาตรฐาน');
  assert.equal((await get('/api/v1/settings', token)).body.data.timeZone, 'Asia/Seoul');
  // นาฬิกาของร้านอ่านเขตเวลาที่ตั้งไว้: 15:30 UTC คือ 00:30 ของวันถัดไปที่โซล
  assert.equal(storeClock.today(new Date('2026-09-26T15:30:00Z')), '2026-09-27');
  assert.deepEqual(storeClock.dayRange('2026-09-27'), {
    start: '2026-09-26T15:00:00.000Z',
    end: '2026-09-27T15:00:00.000Z',
  });

  for (const bad of ['Bangkok', '+07:00', 'Mars/Olympus']) {
    const res = await patch('/api/v1/settings', token, { timeZone: bad });
    assert.equal(res.status, 400, bad);
    assert.match(res.body.error.message, /IANA/);
  }
  const en = await patch('/api/v1/settings', token, { timeZone: 'Bangkok' }).set(
    'Accept-Language',
    'en',
  );
  assert.equal(
    en.body.error.message,
    '"Bangkok" is not an IANA time zone name (for example Asia/Bangkok)',
  );
  assert.equal((await get('/api/v1/settings', token)).body.data.timeZone, 'Asia/Seoul');

  const restored = await patch('/api/v1/settings', token, { timeZone: 'Asia/Bangkok' });
  assert.equal(restored.body.data.timeZone, 'Asia/Bangkok');
});
