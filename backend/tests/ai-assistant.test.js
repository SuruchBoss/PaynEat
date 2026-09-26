// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';
import { setAnthropicClientForTests } from '../src/modules/ai-assistant/ai-assistant.llm-client.js';

after(() => {
  setAnthropicClientForTests(undefined);
  cleanup();
});

const post = (url, token, body) => api().post(url).set(authHeader(token)).send(body);

/** fake Anthropic client — คืนค่าที่ queue ไว้ตามลำดับ พร้อมจด request ทุกครั้งไว้ให้ตรวจสอบได้ */
const fakeClient = (responses) => {
  const calls = [];
  return {
    calls,
    messages: {
      create: async (params) => {
        calls.push(params);
        if (calls.length > responses.length) {
          throw new Error('fakeClient: หมด response ที่ queue ไว้แล้ว');
        }
        return responses[calls.length - 1];
      },
    },
  };
};

const toolUse = (id, name, input) => ({
  content: [{ type: 'tool_use', id, name, input }],
  stop_reason: 'tool_use',
  usage: { input_tokens: 100, output_tokens: 50 },
});

const submitAnswer = (id, input) => toolUse(id, 'submit_answer', input);

test('POST /ai/ask — พนักงานเสิร์ฟ/ครัว/แคชเชียร์เข้าไม่ได้ สงวนไว้เฉพาะ admin/manager', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const kitchen = await login('kitchen', 'kitchen123');
  const cashier = await login('cashier', 'cashier123');

  assert.equal(
    (await post('/api/v1/ai/ask', waiter.token, { question: 'ยอดขายวันนี้เท่าไร' })).status,
    403,
  );
  assert.equal(
    (await post('/api/v1/ai/ask', kitchen.token, { question: 'ยอดขายวันนี้เท่าไร' })).status,
    403,
  );
  assert.equal(
    (await post('/api/v1/ai/ask', cashier.token, { question: 'ยอดขายวันนี้เท่าไร' })).status,
    403,
  );
});

test('POST /ai/ask — คำถามว่างต้องถูกปฏิเสธ (422)', async () => {
  const manager = await login('manager', 'manager123');
  setAnthropicClientForTests(fakeClient([]));
  const res = await post('/api/v1/ai/ask', manager.token, { question: '' });
  assert.equal(res.status, 422);
});

test('POST /ai/ask — ยังไม่ได้ตั้งค่า ANTHROPIC_API_KEY ต้องตอบ 503 พร้อม code เฉพาะ', async () => {
  const manager = await login('manager', 'manager123');
  setAnthropicClientForTests(null);

  const res = await post('/api/v1/ai/ask', manager.token, { question: 'ยอดขายวันนี้เท่าไร' });
  assert.equal(res.status, 503);
  assert.equal(res.body.error.code, 'AI_ASSISTANT_DISABLED');
});

test('POST /ai/ask — manager ถามยอดขายได้ AI เรียก tool จริงแล้วตอบพร้อมกราฟและระบุที่มา', async () => {
  const manager = await login('manager', 'manager123');
  const client = fakeClient([
    toolUse('call_1', 'get_sales_summary', { from: '2026-09-17', to: '2026-09-17' }),
    submitAnswer('call_2', {
      answerText: 'จากข้อมูลวันที่ 2026-09-17 ยอดขายรวม 0 บาท',
      chart: { title: 'ยอดขายรายวัน', points: [{ label: '17 ก.ย.', value: 0 }] },
    }),
  ]);
  setAnthropicClientForTests(client);

  const res = await post('/api/v1/ai/ask', manager.token, { question: 'ยอดขายวันนี้เท่าไร' });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.match(res.body.data.answerText, /2026-09-17/);
  assert.equal(res.body.data.chart.points[0].value, 0);
  assert.equal(res.body.data.sources.length, 1);
  assert.equal(res.body.data.sources[0].tool, 'get_sales_summary');
  assert.equal(typeof res.body.data.remainingToday, 'number');

  // tool ที่ยื่นให้โมเดลต้องไม่มี list_audit_log_entries เพราะ manager ไม่ใช่ admin
  const toolNames = client.calls[0].tools.map((t) => t.name);
  assert.ok(!toolNames.includes('list_audit_log_entries'), 'manager ไม่ควรเห็น tool ของ audit log');
  assert.ok(toolNames.includes('get_sales_summary'));
});

test('POST /ai/ask — admin เห็น tool audit log ด้วย (manager ไม่เห็น)', async () => {
  const admin = await login('admin', 'admin123');
  const client = fakeClient([submitAnswer('call_1', { answerText: 'ไม่มีข้อมูลที่เกี่ยวข้อง' })]);
  setAnthropicClientForTests(client);

  const res = await post('/api/v1/ai/ask', admin.token, { question: 'มีใครยกเลิกออเดอร์บ้าง' });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  const toolNames = client.calls[0].tools.map((t) => t.name);
  assert.ok(toolNames.includes('list_audit_log_entries'), 'admin ควรเห็น tool ของ audit log');
});

test('POST /ai/ask — พารามิเตอร์ tool ผิด schema ต้องถูกปฏิเสธและให้โมเดลแก้ไขเอง ไม่ล้มทั้งคำขอ', async () => {
  const manager = await login('manager', 'manager123');
  const client = fakeClient([
    toolUse('call_1', 'get_top_selling_items', { limit: 999 }), // เกิน max 50 — ต้องโดน validate ปฏิเสธ
    submitAnswer('call_2', { answerText: 'เมนูขายดีที่สุดคือ...' }),
  ]);
  setAnthropicClientForTests(client);

  const res = await post('/api/v1/ai/ask', manager.token, { question: 'เมนูไหนขายดีสุด' });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  // รอบแรก tool ทำงานผิดพลาด จึงไม่ควรถูกนับเป็น source ที่ใช้จริง
  assert.equal(res.body.data.sources.length, 0);

  // request รอบที่สองต้องมี tool_result แบบ is_error ส่งกลับไปบอกโมเดลว่าพารามิเตอร์ผิด
  const secondRequestMessages = client.calls[1].messages;
  const toolResultMessage = secondRequestMessages[secondRequestMessages.length - 1];
  const toolResult = toolResultMessage.content[0];
  assert.equal(toolResult.is_error, true);
  assert.match(toolResult.content, /พารามิเตอร์ไม่ถูกต้อง/);
});

test('POST /ai/ask — ถ้าโมเดลไม่ยอมเรียก submit_answer เอง ต้องถูกบังคับในรอบสุดท้าย (กันวนไม่จบ)', async () => {
  const manager = await login('manager', 'manager123');
  // 5 รอบแรก AI เลือกเรียก tool อ่านข้อมูลเรื่อยๆ ไม่เรียก submit_answer เอง รอบที่ 6 (สุดท้าย) ถูก
  // บังคับด้วย tool_choice ให้ต้องเรียก submit_answer เท่านั้น
  const responses = Array.from({ length: 5 }, (_, i) =>
    toolUse(`call_${i}`, 'get_sales_summary', {}),
  );
  responses.push(submitAnswer('call_final', { answerText: 'สรุปผลจากข้อมูลที่รวบรวมได้' }));
  const client = fakeClient(responses);
  setAnthropicClientForTests(client);

  const res = await post('/api/v1/ai/ask', manager.token, { question: 'วิเคราะห์ร้านให้หน่อย' });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.equal(client.calls.length, 6, 'ต้องหยุดที่ MAX_ROUNDS พอดี ไม่วนต่อไม่จบ');
  assert.deepEqual(client.calls[0].tool_choice, { type: 'auto' });
  assert.deepEqual(client.calls[5].tool_choice, { type: 'tool', name: 'submit_answer' });
});

test('POST /ai/ask — โมเดลตอบข้อความเฉยๆ โดยไม่เรียก submit_answer ต้องไม่ถูกรับเป็นคำตอบสุดท้าย', async () => {
  const manager = await login('manager', 'manager123');
  // รอบแรกโมเดลตอบข้อความดิบเฉยๆ (ผิดกฎ #6) — ต้องไม่ถูกยอมรับเป็นคำตอบ ต้องถูกป้อนกลับเข้าลูป
  // ให้ลองใหม่ รอบสองเรียก submit_answer ถูกต้อง คำตอบสุดท้ายต้องมาจากรอบสองเท่านั้น
  const rawTextRound = {
    content: [{ type: 'text', text: 'ยอดขายน่าจะประมาณ 5000 บาท' }],
    stop_reason: 'end_turn',
    usage: { input_tokens: 50, output_tokens: 20 },
  };
  const client = fakeClient([
    rawTextRound,
    submitAnswer('call_2', { answerText: 'จากข้อมูล get_sales_summary ยอดขายวันนี้ 0 บาท' }),
  ]);
  setAnthropicClientForTests(client);

  const res = await post('/api/v1/ai/ask', manager.token, { question: 'ยอดขายวันนี้เท่าไร' });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.equal(res.body.data.answerText, 'จากข้อมูล get_sales_summary ยอดขายวันนี้ 0 บาท');
  assert.doesNotMatch(
    res.body.data.answerText,
    /5000/,
    'ห้ามหลุดคำตอบดิบที่ไม่ผ่าน submit_answer ออกไป',
  );
  assert.equal(client.calls.length, 2, 'ต้องเรียกโมเดลรอบสองแทนที่จะรับข้อความดิบจากรอบแรก');

  const secondRequestMessages = client.calls[1].messages;
  const correction = secondRequestMessages[secondRequestMessages.length - 1];
  assert.equal(correction.role, 'user');
  assert.match(correction.content, /submit_answer/);
});

test('POST /ai/ask — โมเดลถูกปฏิเสธ (refusal) ต้องตอบข้อความสุภาพแทนที่จะพัง', async () => {
  const manager = await login('manager', 'manager123');
  const client = fakeClient([
    { content: [], stop_reason: 'refusal', usage: { input_tokens: 10, output_tokens: 0 } },
  ]);
  setAnthropicClientForTests(client);

  const res = await post('/api/v1/ai/ask', manager.token, { question: 'คำถามที่โมเดลปฏิเสธ' });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.ok(res.body.data.answerText.length > 0);
  assert.equal(res.body.data.sources.length, 0);
});
