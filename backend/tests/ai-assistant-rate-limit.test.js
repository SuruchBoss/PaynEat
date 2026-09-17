import test, { after } from 'node:test';
import assert from 'node:assert/strict';

// ต้องตั้งค่า env ก่อน import โมดูลที่อ่าน config — เหมือนกับที่ helpers/testApp.js ทำ (คอมเมนต์ในนั้น
// อธิบายเหตุผลไว้แล้ว) จึงใช้ dynamic import แยกไฟล์นี้ต่างหากจากเทสต์อื่นของ ai-assistant เพื่อตั้งค่า
// โควตาต่ำๆ ทดสอบ rate limit โดยไม่กระทบเทสต์ไฟล์อื่นที่ใช้ค่า default (แต่ละไฟล์ทดสอบรันคนละ process)
process.env.AI_ASSISTANT_DAILY_LIMIT = '1';

const { api, login, authHeader, cleanup } = await import('./helpers/testApp.js');
const { setAnthropicClientForTests } =
  await import('../src/modules/ai-assistant/ai-assistant.llm-client.js');

after(cleanup);

const post = (url, token, body) => api().post(url).set(authHeader(token)).send(body);

const fakeClient = () => ({
  messages: {
    create: async () => ({
      content: [
        { type: 'tool_use', id: 'call_1', name: 'submit_answer', input: { answerText: 'ตอบแล้ว' } },
      ],
      stop_reason: 'tool_use',
      usage: { input_tokens: 10, output_tokens: 5 },
    }),
  },
});

test('POST /ai/ask — ถามเกินโควตาต่อวันต้องถูกปฏิเสธด้วย 429', async () => {
  const manager = await login('manager', 'manager123');
  setAnthropicClientForTests(fakeClient());

  const first = await post('/api/v1/ai/ask', manager.token, { question: 'คำถามที่ 1' });
  assert.equal(first.status, 200, JSON.stringify(first.body));
  assert.equal(first.body.data.remainingToday, 0);

  const second = await post('/api/v1/ai/ask', manager.token, { question: 'คำถามที่ 2' });
  assert.equal(second.status, 429, JSON.stringify(second.body));
  assert.equal(second.body.error.code, 'AI_ASSISTANT_RATE_LIMITED');
});
