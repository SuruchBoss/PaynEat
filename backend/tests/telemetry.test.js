// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after, afterEach, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

// ต้อง import หลัง helpers/testApp.js ตั้ง env แล้ว
const { env } = await import('../src/config/env.js');
const { setLogSink } = await import('../src/core/telemetry/logger.js');
const { startMetricsServer } = await import('../src/core/telemetry/metrics.js');
const { userRepository } = await import('../src/modules/users/user.repository.js');
const { branchRepository } = await import('../src/modules/branches/branch.repository.js');

// log และ metric ตามสัญญา telemetry v1.1 ของระบบนิเวศ PaynEat (docs/tickets/24-telemetry-contract.md) —
// ยิงคำขอจริงเข้าแอปจริงบนฐานข้อมูลจริง แล้วตรวจบรรทัด log ที่แอปเขียนออกมาจริง ๆ

let lines = [];
let restoreSink;
const originalTelemetry = { ...env.telemetry };

beforeEach(() => {
  lines = [];
  restoreSink = setLogSink((line) => lines.push(line));
});

afterEach(() => {
  setLogSink(restoreSink);
  Object.assign(env.telemetry, originalTelemetry);
});

let metricsServer;
after(() => {
  metricsServer?.close();
  cleanup();
});

const records = () => lines.map((line) => JSON.parse(line));

/** `finish` ฝั่งเซิร์ฟเวอร์อาจมาหลัง supertest ได้คำตอบเล็กน้อย — รอบรรทัดของคำขอนั้นแทนการเดาเวลา */
const completedLine = async (requestId) => {
  for (let i = 0; i < 100; i += 1) {
    const found = records().find(
      (r) =>
        (r.labels ?? r['logging.googleapis.com/labels'])?.event === 'http.request.completed' &&
        (r.labels ?? r['logging.googleapis.com/labels'])?.correlation_id === requestId,
    );
    if (found) return found;
    await new Promise((resolve) => setTimeout(resolve, 10));
  }
  throw new Error(`ไม่มีบรรทัด http.request.completed ของ ${requestId}\n${lines.join('\n')}`);
};

const RFC3339_MS = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

test('ทุกบรรทัดเป็น JSON ตามสัญญา: severity เป็นข้อความ, time, message, labels ธรรมดา ไม่มีชื่อ vendor', async () => {
  const res = await api().get('/health').set('x-request-id', 'health-check-0001');
  assert.equal(res.status, 200);

  const line = await completedLine('health-check-0001');
  assert.equal(line.severity, 'INFO');
  assert.match(line.time, RFC3339_MS);
  assert.equal(line.message, 'GET /health 200');
  assert.deepEqual(line.labels, {
    app: 'payneat-pos-api',
    event: 'http.request.completed',
    correlation_id: 'health-check-0001',
  });
  assert.deepEqual(Object.keys(line.httpRequest), [
    'requestMethod',
    'requestUrl',
    'status',
    'latency',
  ]);
  assert.equal(line.httpRequest.requestUrl, '/health');
  assert.equal(line.httpRequest.status, 200);
  assert.match(line.httpRequest.latency, /^\d+\.\d{3}s$/);
  assert.equal(
    lines.some((l) => l.includes('googleapis')),
    false,
    'รูปแบบค่าเริ่มต้นต้องไม่มี key ของ vendor ใดๆ',
  );
});

test('x-request-id ไปกลับ: ใช้ของผู้เรียกถ้าถูกรูปแบบ, สร้างใหม่ถ้าไม่ถูกหรือไม่ส่งมา, อยู่ใน header/log/error body', async () => {
  const echoed = await api()
    .get('/health')
    .set('Origin', 'http://localhost:8080')
    .set('x-request-id', 'pos-abc123def456');
  assert.equal(echoed.headers['x-request-id'], 'pos-abc123def456');
  // แอปเว็บอยู่คนละ origin กับ API — เบราว์เซอร์ให้อ่าน header นี้ได้เฉพาะเมื่อประกาศ expose ไว้
  assert.match(echoed.headers['access-control-expose-headers'], /x-request-id/i);

  const replaced = await api().get('/health').set('x-request-id', 'bad id!');
  assert.match(replaced.headers['x-request-id'], UUID);
  await completedLine(replaced.headers['x-request-id']);

  const generated = await api().get('/health');
  assert.match(generated.headers['x-request-id'], UUID);

  const failed = await api().get('/api/v1/no-such-route').set('x-request-id', 'pos-error-000001');
  assert.equal(failed.status, 404);
  assert.equal(failed.headers['x-request-id'], 'pos-error-000001');
  assert.equal(failed.body.error.requestId, 'pos-error-000001');
  const line = await completedLine('pos-error-000001');
  assert.equal(line.severity, 'INFO', '404 ไม่ใช่ความผิดพลาดที่ต้องเตือนตามสัญญา');
});

test('LOG_FORMAT=gcp: labels อยู่ใต้ logging.googleapis.com/labels และ trace เป็น resource name ของ Cloud Logging', async () => {
  env.telemetry.logFormat = 'gcp';
  env.telemetry.gcpProject = 'demo-project';

  await api()
    .get('/health')
    .set('x-request-id', 'gcp-format-0001')
    .set('traceparent', '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01');

  const line = await completedLine('gcp-format-0001');
  assert.equal('labels' in line, false);
  assert.equal('trace' in line, false);
  assert.deepEqual(line['logging.googleapis.com/labels'], {
    app: 'payneat-pos-api',
    event: 'http.request.completed',
    correlation_id: 'gcp-format-0001',
  });
  assert.equal(
    line['logging.googleapis.com/trace'],
    'projects/demo-project/traces/4bf92f3577b34da6a3ce929d0e0e4736',
  );
});

test('รูปแบบค่าเริ่มต้นส่งต่อ traceparent เป็น trace ธรรมดา', async () => {
  await api()
    .get('/health')
    .set('x-request-id', 'trace-plain-0001')
    .set('traceparent', '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01');
  assert.equal((await completedLine('trace-plain-0001')).trace, '4bf92f3577b34da6a3ce929d0e0e4736');
});

test('severity ตาม status: 401 = INFO, 422 = WARNING และบรรทัดของพนักงานที่ล็อกอินมี location_code ของสาขา', async () => {
  const unauthorized = await api().get('/api/v1/customers').set('x-request-id', 'no-token-000001');
  assert.equal(unauthorized.status, 401);
  assert.equal((await completedLine('no-token-000001')).severity, 'INFO');

  const cashier = await login('cashier', 'cashier123');
  const branchCode = branchRepository.findById(cashier.user.branchId).code;
  const invalid = await api()
    .post('/api/v1/customers')
    .set(authHeader(cashier.token))
    .set('x-request-id', 'bad-body-000001')
    .send({ name: '', phone: 'x' });
  assert.equal(invalid.status, 422);

  const line = await completedLine('bad-body-000001');
  assert.equal(line.severity, 'WARNING');
  // POST มี body — บริบทของคำขอต้องตามไปถึง auth หลัง body parser อ่าน body จาก event ของ stream เสร็จ
  // (raw-body ผูก callback ด้วย AsyncResource ให้อยู่แล้ว ถ้าวันไหนเลิกผูก เทสต์นี้จะล้ม)
  assert.equal(line.labels.location_code, branchCode);
});

test('500: บรรทัดเดียวระดับ ERROR พร้อม error {type, message} — stack เฉพาะ LOG_LEVEL=DEBUG', async (t) => {
  const { token } = await login('cashier', 'cashier123');
  const original = userRepository.findById;
  t.after(() => {
    userRepository.findById = original;
  });
  userRepository.findById = () => {
    throw new TypeError('simulated failure');
  };

  const res = await api()
    .get('/api/v1/customers')
    .set(authHeader(token))
    .set('x-request-id', 'crash-info-00001');
  assert.equal(res.status, 500);
  assert.equal(res.body.error.requestId, 'crash-info-00001');
  const line = await completedLine('crash-info-00001');
  assert.equal(line.severity, 'ERROR');
  assert.deepEqual(line.error, { type: 'TypeError', message: 'simulated failure' });
  assert.equal(
    records().filter((r) => r.labels.correlation_id === 'crash-info-00001').length,
    1,
    'คำขอหนึ่งครั้งต้องได้ log บรรทัดเดียว ไม่ใช่ซ้ำจาก errorHandler อีกบรรทัด',
  );

  env.telemetry.logLevel = 'DEBUG';
  await api()
    .get('/api/v1/customers')
    .set(authHeader(token))
    .set('x-request-id', 'crash-debug-0001');
  assert.match((await completedLine('crash-debug-0001')).error.stack, /simulated failure/);
});

test('LOG_LEVEL=WARNING ไม่เขียนบรรทัด INFO', async () => {
  env.telemetry.logLevel = 'WARNING';
  await api().get('/health').set('x-request-id', 'quiet-level-0001');
  await new Promise((resolve) => setTimeout(resolve, 50));
  assert.equal(lines.length, 0);
});

test('/metrics: นับตาม route template ไม่ใช่ path จริง และไม่ได้อยู่บนพอร์ต API', async () => {
  metricsServer = await startMetricsServer({ port: 0, host: '127.0.0.1' });
  const scrape = async () => {
    const res = await fetch(`http://127.0.0.1:${metricsServer.address().port}/metrics`);
    assert.equal(res.status, 200);
    assert.match(res.headers.get('content-type'), /text\/plain/);
    return res.text();
  };

  const { token } = await login('cashier', 'cashier123');
  const created = await api()
    .post('/api/v1/customers')
    .set(authHeader(token))
    .send({ name: 'ลูกค้าเมตริก', phone: `08${Date.now().toString().slice(-8)}` });
  const customerId = created.body.data.id;
  await api().get(`/api/v1/customers/${customerId}`).set(authHeader(token));
  await api().get('/wp-login.php');
  await api().get('/api/v1/orders/123');

  const text = await scrape();
  assert.match(
    text,
    /http_requests_total\{app="payneat-pos-api",method="GET",route="\/api\/v1\/customers\/:id",status="200"\} \d+/,
  );
  assert.match(
    text,
    /http_request_duration_seconds_bucket\{le="[\d.]+",app="payneat-pos-api",method="GET",route="\/api\/v1\/customers\/:id"\}/,
  );
  assert.doesNotMatch(text, new RegExp(`/api/v1/customers/${customerId}"`));
  assert.match(text, /route="unmatched",status="404"/);
  // 401 จาก authenticate ระดับ router จบก่อนถึง route ได้ mount ของโมดูลแทน ไม่ใช่ path จริง
  assert.match(text, /method="GET",route="\/api\/v1\/orders\/\*",status="401"/);
  assert.doesNotMatch(text, /\/api\/v1\/orders\/123/);

  const onApiPort = await api().get('/metrics');
  assert.equal(onApiPort.status, 404, '/metrics ต้องไม่ถูกเสิร์ฟบนพอร์ต API ที่เปิดสาธารณะ');
});

test('ไม่มีข้อมูลส่วนบุคคล รหัสผ่าน หรือ query string ใน log: login, สร้าง/แก้ลูกค้า, ค้นหาด้วยเบอร์', async () => {
  const secrets = {
    name: 'คุณลับเฉพาะ ทดสอบล็อก',
    phone: `089${Date.now().toString().slice(-7)}`,
    email: 'private.person@example.com',
    taxId: '1103700012345',
    address: '77/7 ซอยลับเฉพาะ แขวงทดสอบ',
    newEmail: 'billing.private@example.com',
  };

  await api()
    .post('/api/v1/auth/login')
    .send({ username: 'cashier', password: 'definitely-wrong-pw' });
  const manager = await login('manager', 'manager123');
  const created = await api()
    .post('/api/v1/customers')
    .set(authHeader(manager.token))
    .send({ name: secrets.name, phone: secrets.phone, email: secrets.email });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  const updated = await api()
    .patch(`/api/v1/customers/${created.body.data.id}/credit`)
    .set(authHeader(manager.token))
    .send({
      creditLimit: 5000,
      creditTermDays: 30,
      taxId: secrets.taxId,
      address: secrets.address,
      email: secrets.newEmail,
    });
  assert.equal(updated.status, 200, JSON.stringify(updated.body));
  const search = await api()
    .get(`/api/v1/customers?search=${secrets.phone}`)
    .set(authHeader(manager.token))
    .set('x-request-id', 'search-phone-001');
  assert.equal(search.status, 200);

  const line = await completedLine('search-phone-001');
  assert.equal(line.httpRequest.requestUrl, '/api/v1/customers');

  const everything = lines.join('\n');
  for (const value of [
    ...Object.values(secrets),
    'manager123',
    'definitely-wrong-pw',
    manager.token,
    'สมชาย (ผู้จัดการ)',
  ]) {
    assert.equal(everything.includes(value), false, `พบ "${value}" ใน log`);
  }
});

test('JSON พังที่มีรหัสผ่านอยู่ = 400 ไม่ใช่ 500 และเนื้อ body ไม่หลุดไปอยู่ใน log', async () => {
  const res = await api()
    .post('/api/v1/auth/login')
    .set('Content-Type', 'application/json')
    .set('Accept-Language', 'en')
    .set('x-request-id', 'broken-json-0001')
    .send('{"username":"cashier","password":"leaky-secret-pw"');
  assert.equal(res.status, 400);
  assert.equal(res.body.error.code, 'BAD_REQUEST');
  assert.equal(res.body.error.message, 'Some of the information entered is invalid');

  const line = await completedLine('broken-json-0001');
  assert.equal(line.severity, 'WARNING');
  assert.equal(lines.join('\n').includes('leaky-secret-pw'), false);
});

test('QR สั่งอาหารเอง: token ของโต๊ะไม่อยู่ใน log แม้แต่ path ที่ไม่มีจริง', async () => {
  const { token } = await login('admin', 'admin123');
  const table = (await api().get('/api/v1/tables').set(authHeader(token))).body.data[0];

  const menu = await api()
    .get(`/api/v1/public/tables/${table.qrToken}/menu`)
    .set('x-request-id', 'qr-menu-0000001');
  assert.equal(menu.status, 200);
  await api()
    .get(`/api/v1/public/tables/${table.qrToken}/typo`)
    .set('x-request-id', 'qr-typo-0000001');

  assert.equal(
    (await completedLine('qr-menu-0000001')).httpRequest.requestUrl,
    '/api/v1/public/tables/:qrToken/menu',
  );
  assert.equal(
    (await completedLine('qr-typo-0000001')).httpRequest.requestUrl,
    '/api/v1/public/tables/:qrToken/typo',
  );
  assert.equal(lines.join('\n').includes(table.qrToken), false);
});
