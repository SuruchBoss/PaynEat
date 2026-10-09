// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import {
  isValidTimeZone,
  normalizeTimeZone,
  storeDate,
  storeDayRange,
  storeNow,
} from '../src/core/storeTime.js';

// วันและเวลาของร้านตามเขตเวลาที่ร้านตั้ง ไม่ขึ้นกับ TZ ของเครื่องเซิร์ฟเวอร์ (T03 #94, docs/DECISIONS.md #101)

test('20:00 UTC ของวันที่ 26 คือวันที่ 27 ของร้าน Asia/Bangkok และวันที่ 27 คือ [26T17:00Z, 27T17:00Z)', () => {
  assert.equal(storeDate('2026-09-26T20:00:00Z', 'Asia/Bangkok'), '2026-09-27');
  assert.equal(storeDate('2026-09-26T16:59:59Z', 'Asia/Bangkok'), '2026-09-26');
  assert.deepEqual(storeDayRange('2026-09-27', 'Asia/Bangkok'), {
    start: '2026-09-26T17:00:00.000Z',
    end: '2026-09-27T17:00:00.000Z',
  });
  assert.deepEqual(storeNow('Asia/Bangkok', new Date('2026-09-26T20:00:00Z')), {
    timeZone: 'Asia/Bangkok',
    date: '2026-09-27',
    time: '03:00:00',
  });
});

test('วันที่เปลี่ยนเวลาออมแสงยาว 23 หรือ 25 ชั่วโมงตามจริง และวันที่เที่ยงคืนถูกข้ามเริ่มตอนเลื่อนเวลา', () => {
  assert.deepEqual(storeDayRange('2026-03-08', 'America/New_York'), {
    start: '2026-03-08T05:00:00.000Z',
    end: '2026-03-09T04:00:00.000Z',
  });
  assert.deepEqual(storeDayRange('2026-11-01', 'America/New_York'), {
    start: '2026-11-01T04:00:00.000Z',
    end: '2026-11-02T05:00:00.000Z',
  });
  // ชิลีเลื่อนนาฬิกาจาก 00:00 ไป 01:00 ของวันที่ 8 ก.ย. 2024 — ไม่มีเที่ยงคืน วันเริ่มที่ 04:00Z
  assert.deepEqual(storeDayRange('2024-09-08', 'America/Santiago'), {
    start: '2024-09-08T04:00:00.000Z',
    end: '2024-09-09T03:00:00.000Z',
  });
  // เลื่อนครึ่งชั่วโมง
  assert.deepEqual(storeDayRange('2026-10-04', 'Australia/Lord_Howe'), {
    start: '2026-10-03T13:30:00.000Z',
    end: '2026-10-04T13:00:00.000Z',
  });
});

test('รับเฉพาะชื่อเขตเวลา IANA และเก็บเป็นตัวพิมพ์มาตรฐาน', () => {
  assert.equal(normalizeTimeZone('asia/bangkok'), 'Asia/Bangkok');
  assert.equal(normalizeTimeZone(' Asia/Seoul '), 'Asia/Seoul');
  assert.equal(normalizeTimeZone('UTC'), 'UTC');
  for (const bad of ['Bangkok', '+07:00', 'EST', 'Mars/Olympus', '', null, 7]) {
    assert.equal(isValidTimeZone(bad), false, String(bad));
  }
  assert.throws(() => storeDayRange('27/09/2026', 'Asia/Bangkok'), TypeError);
});

test('ผลเหมือนกันเมื่อเครื่องตั้ง TZ=UTC, TZ=Asia/Bangkok และ TZ=America/Los_Angeles', () => {
  const module = fileURLToPath(new URL('../src/core/storeTime.js', import.meta.url));
  const script = `
    const t = await import(${JSON.stringify(module)});
    console.log(JSON.stringify([
      t.storeDate('2026-09-26T20:00:00Z', 'Asia/Bangkok'),
      t.storeDayRange('2026-09-27', 'Asia/Bangkok'),
      t.storeDayRange('2026-03-08', 'America/New_York'),
      t.storeNow('Asia/Bangkok', new Date('2026-09-26T20:00:00Z')),
    ]));`;
  const run = (tz) =>
    execFileSync(process.execPath, ['--input-type=module', '-e', script], {
      env: { ...process.env, TZ: tz },
      encoding: 'utf8',
    });
  const results = ['UTC', 'Asia/Bangkok', 'America/Los_Angeles'].map(run);
  assert.equal(results[1], results[0]);
  assert.equal(results[2], results[0]);
  assert.deepEqual(JSON.parse(results[0])[1], {
    start: '2026-09-26T17:00:00.000Z',
    end: '2026-09-27T17:00:00.000Z',
  });
});
