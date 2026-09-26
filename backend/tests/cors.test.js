// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { parseCorsOrigin } from '../src/config/cors.js';

// ตั้งเหมือน .env.example และ docker-compose.yml — ต้องตั้งก่อน import แอป (env อ่านค่าตอน import)
process.env.CORS_ORIGIN = '*';
const { api, cleanup } = await import('./helpers/testApp.js');

after(cleanup);

test('parseCorsOrigin: ไม่ตั้ง/ว่าง/มี * = wildcard string, ระบุหลายค่าได้ array ที่ตัดช่องว่างแล้ว', () => {
  assert.equal(parseCorsOrigin(undefined), '*');
  assert.equal(parseCorsOrigin(''), '*');
  assert.equal(parseCorsOrigin('*'), '*');
  assert.equal(parseCorsOrigin(' * '), '*');
  assert.equal(parseCorsOrigin('http://a.test, *'), '*');
  assert.deepEqual(parseCorsOrigin('http://a.test, http://b.test'), [
    'http://a.test',
    'http://b.test',
  ]);
});

test('CORS_ORIGIN=* : แอปเว็บที่รันคนละพอร์ตกับ API (flutter run -d chrome / Docker :8080) ล็อกอินได้', async () => {
  const origin = 'http://localhost:8080';
  const preflight = await api()
    .options('/api/v1/auth/login')
    .set('Origin', origin)
    .set('Access-Control-Request-Method', 'POST')
    .set('Access-Control-Request-Headers', 'content-type,authorization');
  assert.equal(preflight.status, 204);
  assert.equal(preflight.headers['access-control-allow-origin'], '*');

  const res = await api()
    .post('/api/v1/auth/login')
    .set('Origin', origin)
    .send({ username: 'cashier', password: 'cashier123' });
  assert.equal(res.status, 200);
  assert.equal(res.headers['access-control-allow-origin'], '*');
});
