// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test from 'node:test';
import assert from 'node:assert/strict';
import {
  acceptRequestId,
  formatLatency,
  isEnabled,
  isLocationCode,
  parseTraceparent,
  redactPath,
  requestPath,
  severityForStatus,
  toLogRecord,
} from '../src/core/telemetry/logRecord.js';
import { messageTemplate } from '../src/i18n/errorMessages.js';

// กฎของสัญญา telemetry v1.1 เป็น pure function (ดู src/core/telemetry/logRecord.js) — ตัวอย่างเดียวกับเทสต์ของ
// PaynEat ERP (log-record.spec.ts) เพื่อให้ทั้งสองระบบเขียน log หน้าตาเดียวกันจริง (ticket 24)

test('severity ของ http.request.completed: INFO, WARNING สำหรับ 4xx ยกเว้น 401/404, ERROR สำหรับ 5xx', () => {
  const cases = [
    [200, 'INFO'],
    [201, 'INFO'],
    [304, 'INFO'],
    [401, 'INFO'],
    [404, 'INFO'],
    [400, 'WARNING'],
    [403, 'WARNING'],
    [409, 'WARNING'],
    [422, 'WARNING'],
    [500, 'ERROR'],
    [503, 'ERROR'],
  ];
  for (const [status, severity] of cases) assert.equal(severityForStatus(status), severity, status);
});

test('latency เป็นข้อความหน่วยวินาทีมี s ต่อท้าย ไม่ใช่ตัวเลข', () => {
  assert.equal(formatLatency(231.4), '0.231s');
  assert.equal(formatLatency(4), '0.004s');
  assert.equal(formatLatency(1500), '1.500s');
  assert.equal(formatLatency(-3), '0.000s');
});

test('requestUrl เก็บแค่ path — query string และ fragment ถูกตัดทิ้ง', () => {
  assert.equal(requestPath('/api/v1/customers?search=0812345678&token=abc'), '/api/v1/customers');
  assert.equal(requestPath('/health'), '/health');
  assert.equal(requestPath('/a#fragment'), '/a');
});

test('QR token ของโต๊ะใน path ถูกแทนด้วย :qrToken เสมอ ทั้ง route ที่มีจริงและ path ที่ไม่มี', () => {
  const token = '5f0c7c1e-8a52-4d3b-9d7e-3f1f2b6a9c10';
  assert.equal(
    redactPath(`/api/v1/public/tables/${token}/items`),
    '/api/v1/public/tables/:qrToken/items',
  );
  assert.equal(redactPath(`/api/v1/public/tables/${token}`), '/api/v1/public/tables/:qrToken');
  assert.equal(
    redactPath(`/api/v1/public/tables/${token}/no-such-page`),
    '/api/v1/public/tables/:qrToken/no-such-page',
  );
  assert.equal(redactPath('/api/v1/tables/7'), '/api/v1/tables/7');
});

test('รับ x-request-id เฉพาะที่ตรง ^[\\w-]{8,64}$', () => {
  assert.equal(acceptRequestId('abcd-1234'), 'abcd-1234');
  assert.equal(acceptRequestId('a'.repeat(64)), 'a'.repeat(64));
  assert.equal(acceptRequestId('short'), undefined);
  assert.equal(acceptRequestId('a'.repeat(65)), undefined);
  assert.equal(acceptRequestId('has space 123'), undefined);
  assert.equal(acceptRequestId('<script>alert(1)</script>'), undefined);
  assert.equal(acceptRequestId(['abcd-1234']), undefined);
  assert.equal(acceptRequestId(undefined), undefined);
});

test('อ่าน trace id จาก W3C traceparent — trace id ศูนย์ทั้งหมดหรือรูปแบบผิดถูกทิ้ง', () => {
  assert.equal(
    parseTraceparent('00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01'),
    '4bf92f3577b34da6a3ce929d0e0e4736',
  );
  assert.equal(
    parseTraceparent('00-00000000000000000000000000000000-00f067aa0ba902b7-01'),
    undefined,
  );
  assert.equal(parseTraceparent('not-a-traceparent'), undefined);
  assert.equal(parseTraceparent(undefined), undefined);
});

test('กรองตาม LOG_LEVEL', () => {
  assert.equal(isEnabled('INFO', 'DEBUG'), false);
  assert.equal(isEnabled('INFO', 'INFO'), true);
  assert.equal(isEnabled('WARNING', 'ERROR'), true);
  assert.equal(isEnabled('ERROR', 'WARNING'), false);
});

test('location_code ใส่ได้เฉพาะรหัสที่ตรงรูปแบบรหัสสถานที่กลาง', () => {
  assert.equal(isLocationCode('SUKHUMVIT'), true);
  assert.equal(isLocationCode('BR-02'), true);
  assert.equal(isLocationCode('สาขา1'), false);
  assert.equal(isLocationCode('main'), false);
  assert.equal(isLocationCode('X'), false);
  assert.equal(isLocationCode(null), false);
});

const entry = {
  severity: 'INFO',
  time: new Date('2026-09-25T10:15:30.123Z'),
  message: 'GET /health 200',
  labels: {
    app: 'payneat-pos-api',
    event: 'http.request.completed',
    correlation_id: 'req-0001-abcd',
    location_code: undefined,
  },
  traceId: '4bf92f3577b34da6a3ce929d0e0e4736',
  httpRequest: { requestMethod: 'GET', requestUrl: '/health', status: 200, latency: '0.004s' },
};

test('รูปแบบค่าเริ่มต้น: labels และ trace เป็น key ธรรมดา ไม่มีชื่อ vendor เลย', () => {
  assert.deepEqual(toLogRecord(entry, { format: 'default', includeStack: false }), {
    severity: 'INFO',
    time: '2026-09-25T10:15:30.123Z',
    message: 'GET /health 200',
    labels: {
      app: 'payneat-pos-api',
      event: 'http.request.completed',
      correlation_id: 'req-0001-abcd',
    },
    trace: '4bf92f3577b34da6a3ce929d0e0e4736',
    httpRequest: { requestMethod: 'GET', requestUrl: '/health', status: 200, latency: '0.004s' },
  });
});

test('LOG_FORMAT=gcp ย้าย labels และ trace ไปที่ key ของ Cloud Logging', () => {
  const record = toLogRecord(entry, {
    format: 'gcp',
    gcpProject: 'demo-project',
    includeStack: false,
  });
  assert.equal('labels' in record, false);
  assert.equal('trace' in record, false);
  assert.deepEqual(record['logging.googleapis.com/labels'], {
    app: 'payneat-pos-api',
    event: 'http.request.completed',
    correlation_id: 'req-0001-abcd',
  });
  assert.equal(
    record['logging.googleapis.com/trace'],
    'projects/demo-project/traces/4bf92f3577b34da6a3ce929d0e0e4736',
  );
});

test('LOG_FORMAT=gcp ที่ไม่ได้ตั้ง project id คง trace ไว้ที่ key ธรรมดา', () => {
  const record = toLogRecord(entry, { format: 'gcp', includeStack: false });
  assert.equal(record.trace, '4bf92f3577b34da6a3ce929d0e0e4736');
  assert.equal('logging.googleapis.com/trace' in record, false);
});

test('stack ของ error ถูกเขียนเฉพาะตอนขอ (LOG_LEVEL=DEBUG)', () => {
  const failing = {
    ...entry,
    severity: 'ERROR',
    error: { type: 'Error', message: 'boom', stack: 'Error: boom\n    at x' },
  };
  assert.deepEqual(toLogRecord(failing, { format: 'default', includeStack: false }).error, {
    type: 'Error',
    message: 'boom',
  });
  assert.deepEqual(toLogRecord(failing, { format: 'default', includeStack: true }).error, {
    type: 'Error',
    message: 'boom',
    stack: 'Error: boom\n    at x',
  });
});

test('ApiError 5xx ลง log เป็นข้อความแม่แบบภาษาอังกฤษ — ค่าที่แทรกไว้ (เช่นคำตอบ SMTP ที่มีอีเมล) ไม่ติดไปด้วย', () => {
  const template = messageTemplate(
    'ส่งอีเมลไม่สำเร็จ: 550 5.1.1 <somchai.private@example.com>: Recipient address rejected',
  );
  assert.ok(template, 'ข้อความส่งอีเมลไม่สำเร็จต้องอยู่ในแคตตาล็อก');
  assert.doesNotMatch(template, /somchai|example\.com/);
  assert.match(template, /\{[a-zA-Z]+\}/);
  assert.equal(messageTemplate('ข้อความที่ไม่อยู่ในแคตตาล็อก'), undefined);
});
