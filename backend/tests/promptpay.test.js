import test from 'node:test';
import assert from 'node:assert/strict';
import { buildPromptPayPayload, crc16ccitt } from '../src/core/promptpay.js';

test('crc16ccitt ตรงกับ test vector มาตรฐานของ CRC-16/CCITT-FALSE', () => {
  // "123456789" ต้องได้ 0x29B1 เสมอ — ใช้ตรวจ implementation ทุกตัวที่อ้างอิงสเปกนี้
  assert.equal(crc16ccitt('123456789').toString(16).toUpperCase(), '29B1');
});

test('buildPromptPayPayload: เบอร์โทร + ไม่ระบุยอด → static QR (POI method 11)', () => {
  const payload = buildPromptPayPayload({ promptPayId: '0812345678' });
  assert.match(payload, /^00020101021129/); // 000201=payload format "01", 010211=POI static "11"
  assert.ok(payload.includes('01130066812345678')); // tag 01 เบอร์โทร แปลงเป็น 66 แล้วครบ 13 หลัก
  assert.ok(payload.includes('A000000677010111')); // GUID พร้อมเพย์
  assert.match(payload, /6304[0-9A-F]{4}$/); // จบด้วย CRC 4 หลัก hex
});

test('buildPromptPayPayload: ระบุยอดเงิน → dynamic QR (POI method 12) พร้อม tag 54', () => {
  const payload = buildPromptPayPayload({ promptPayId: '0812345678', amount: 100 });
  assert.match(payload, /^00020101021229/); // 010212=POI dynamic "12" เพราะระบุยอด
  assert.ok(payload.includes('5406100.00')); // tag 54 ความยาว 6 ค่า "100.00"
});

test('buildPromptPayPayload: เลขผู้เสียภาษี/บัตรประชาชน 13 หลัก ใช้ tag 02 ไม่แปลงเป็นเบอร์โทร', () => {
  const payload = buildPromptPayPayload({ promptPayId: '1234567890123', amount: 25.5 });
  assert.ok(payload.includes('02131234567890123'));
  assert.ok(payload.includes('540525.50'));
});

test('buildPromptPayPayload: ตัดอักขระที่ไม่ใช่ตัวเลขออกจาก promptPayId (เช่น ขีดคั่นเบอร์โทร)', () => {
  const withDashes = buildPromptPayPayload({ promptPayId: '081-234-5678', amount: 10 });
  const plain = buildPromptPayPayload({ promptPayId: '0812345678', amount: 10 });
  assert.equal(withDashes, plain);
});

test('buildPromptPayPayload: CRC เปลี่ยนตามเนื้อหา — คนละยอดต้องได้ CRC คนละค่า', () => {
  const a = buildPromptPayPayload({ promptPayId: '0812345678', amount: 100 });
  const b = buildPromptPayPayload({ promptPayId: '0812345678', amount: 200 });
  const crcOf = (payload) => payload.slice(-4);
  assert.notEqual(crcOf(a), crcOf(b));
});

test('buildPromptPayPayload: payload ยาวถูกต้องตามที่ระบุไว้ในฟิลด์ length ของแต่ละ tag (self-consistent TLV)', () => {
  const payload = buildPromptPayPayload({ promptPayId: '0812345678', amount: 1234.56 });
  let i = 0;
  while (i < payload.length) {
    const len = Number(payload.slice(i + 2, i + 4));
    assert.ok(Number.isInteger(len) && len >= 0, `tag ที่ offset ${i} มีความยาวไม่ใช่ตัวเลข`);
    i += 4 + len;
  }
  assert.equal(i, payload.length, 'ผลรวมความยาวของทุก tag ต้องพอดีกับความยาว payload ทั้งหมด');
});

test('buildPromptPayPayload: promptPayId ว่างเปล่าต้อง throw', () => {
  assert.throws(() => buildPromptPayPayload({ promptPayId: '' }));
  assert.throws(() => buildPromptPayPayload({ promptPayId: '---' }));
});
