// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after, afterEach, before } from 'node:test';
import assert from 'node:assert/strict';
import net from 'node:net';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';
import { parseScaleLine } from '../src/modules/scale/scale.parser.js';
import { scaleService } from '../src/modules/scale/scale.service.js';

// ตาชั่งต่อสาย อ่านน้ำหนักสด (ดู docs/tickets/22-live-scale-camera-scan.md, docs/DECISIONS.md #54)

after(cleanup);
afterEach(() => scaleService.stop());

let waiter;
let kitchen;

before(async () => {
  waiter = await login('waiter1', 'waiter123');
  kitchen = await login('kitchen', 'kitchen123');
});

/** รอจนเงื่อนไขเป็นจริง (สูงสุด timeoutMs) — driver ทำงานผ่าน event loop จึงต้องรอแทนการเช็คทันที */
const waitFor = async (predicate, timeoutMs = 3000) => {
  const started = Date.now();
  while (!predicate()) {
    if (Date.now() - started > timeoutMs) throw new Error('รอเกินเวลา');
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
};

test('อ่านรูปแบบข้อความของตาชั่งยอดนิยมเป็นกรัม พร้อมสถานะนิ่ง/แกว่ง/เกินพิกัด', () => {
  // A&D / CAS
  assert.deepEqual(parseScaleLine('ST,GS,+0000.485kg'), {
    grams: 485,
    stable: true,
    overload: false,
  });
  assert.equal(parseScaleLine('US,GS,+0000.480kg').stable, false);
  assert.deepEqual(parseScaleLine('OL,GS,+9999.999kg'), {
    grams: 0,
    stable: false,
    overload: true,
  });
  assert.equal(parseScaleLine('ST,NT,+  1.250 kg').grams, 1250);
  // ติดลบ (หักภาชนะเกิน) ต้องไม่ถูกนับว่าใช้ได้
  assert.equal(parseScaleLine('ST,NT,-0000.010kg').stable, false);

  // Mettler Toledo MT-SICS
  assert.deepEqual(parseScaleLine('S S      0.485 kg'), {
    grams: 485,
    stable: true,
    overload: false,
  });
  assert.equal(parseScaleLine('S D      0.480 kg').stable, false);
  assert.equal(parseScaleLine('S +').overload, true);
  assert.equal(parseScaleLine('S I'), null);

  // ตัวเลข + หน่วย
  assert.equal(parseScaleLine('0.485 kg').grams, 485);
  assert.equal(parseScaleLine('  485 g').grams, 485);
  assert.equal(parseScaleLine('1 lb').grams, 454);

  for (const garbage of ['', '   ', 'hello', 'ST,GS,', '12345']) {
    assert.equal(parseScaleLine(garbage), null, JSON.stringify(garbage));
  }
});

test('ตาชั่งผ่าน TCP: ต่อบรรทัดที่มาขาดกลางทาง ส่งคำสั่งถามน้ำหนัก และต่อใหม่เองเมื่อสายหลุด', async () => {
  const connections = [];
  const received = [];
  const server = net.createServer((socket) => {
    connections.push(socket);
    socket.on('data', (chunk) => received.push(chunk.toString()));
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();

  try {
    scaleService.start({
      driver: 'tcp',
      host: '127.0.0.1',
      port,
      pollCommand: 'SI',
      pollMs: 30,
    });
    await waitFor(() => connections.length === 1 && scaleService.status().connected);

    // ข้อความหนึ่งบรรทัดมาเป็นสองก้อน (TCP ไม่รับประกันขอบเขตข้อความ)
    connections[0].write('ST,GS,+00');
    connections[0].write('00.485kg\r\nUS,GS,+0000.300kg\r');
    await waitFor(() => scaleService.status().reading?.grams === 300);
    assert.equal(scaleService.status().reading.stable, false);

    connections[0].write('S S      1.020 kg\n');
    await waitFor(() => scaleService.status().reading?.grams === 1020);
    assert.equal(scaleService.status().reading.stable, true);
    assert.ok(received.join('').includes('SI\r\n'), 'ตาชั่งแบบถาม-ตอบต้องได้รับคำสั่ง SI');

    // สายหลุด: น้ำหนักเดิมต้องหายทันที ไม่ค้างให้กดใช้ แล้วต่อใหม่เอง
    connections[0].destroy();
    await waitFor(() => !scaleService.status().connected);
    assert.equal(scaleService.status().reading, null);
    await waitFor(() => connections.length === 2 && scaleService.status().connected, 4000);
  } finally {
    scaleService.stop();
    for (const socket of connections) socket.destroy();
    await new Promise((resolve) => server.close(resolve));
  }
});

test('น้ำหนักที่ไม่อัปเดตเกิน 3 วินาทีถือว่าเก่า ไม่ส่งให้แอป', async (t) => {
  t.mock.timers.enable({ apis: ['Date'], now: Date.now() });
  scaleService.start({ driver: 'simulator', intervalMs: 60_000 });
  scaleService.ingestLine('ST,GS,+0000.485kg');
  assert.equal(scaleService.status().reading.grams, 485);
  t.mock.timers.tick(3500);
  assert.equal(scaleService.status().reading, null);
});

test('GET /scale: ปิดอยู่เป็นค่าเริ่มต้น ตาชั่งจำลองส่งน้ำหนักได้ และครัวไม่มีสิทธิ์ดู', async () => {
  const off = await api().get('/api/v1/scale').set(authHeader(waiter.token));
  assert.equal(off.status, 200);
  assert.equal(off.body.data.enabled, false);
  assert.equal(off.body.data.reading, null);

  scaleService.start({ driver: 'simulator', intervalMs: 20 });
  await waitFor(
    () => scaleService.status().reading?.stable && scaleService.status().reading.grams > 0,
  );
  const on = await api().get('/api/v1/scale').set(authHeader(waiter.token));
  assert.equal(on.body.data.enabled, true);
  assert.equal(on.body.data.driver, 'simulator');
  assert.equal(on.body.data.connected, true);
  assert.ok(on.body.data.reading.grams >= 0);
  assert.ok(on.body.data.reading.at);

  const byKitchen = await api().get('/api/v1/scale').set(authHeader(kitchen.token));
  assert.equal(byKitchen.status, 403);
});

test('SCALE_DRIVER=serial แต่ไม่ได้ตั้งพอร์ต: บอกสาเหตุ ไม่ทำให้เซิร์ฟเวอร์ล้ม', async () => {
  scaleService.start({ driver: 'serial', baudRate: 9600 });
  await waitFor(() => scaleService.status().error !== null);
  const status = scaleService.status();
  assert.equal(status.enabled, true);
  assert.equal(status.connected, false);
  assert.match(status.error, /SCALE_SERIAL_PATH|serialport/);
});
