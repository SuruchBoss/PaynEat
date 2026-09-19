import Anthropic from '@anthropic-ai/sdk';
import { env } from '../../config/env.js';

let client;
let testOverride;

/**
 * คืน client จริง (สร้างครั้งเดียวแล้ว cache ไว้) หรือ null ถ้ายังไม่ได้ตั้ง ANTHROPIC_API_KEY —
 * ผู้เรียก (ai-assistant.service.js) ต้องเช็ค null เองแล้วตอบ 503 ให้ผู้ใช้ ไม่ throw ตรงนี้
 */
export const getAnthropicClient = () => {
  if (testOverride !== undefined) return testOverride;
  if (!env.aiAssistant.apiKey) return null;
  if (!client) client = new Anthropic({ apiKey: env.aiAssistant.apiKey });
  return client;
};

/**
 * ใช้เฉพาะใน test เพื่อสลับเป็น fake client แทนของจริง (กัน test เรียก Anthropic API จริงโดยไม่ตั้งใจ
 * ซึ่งจะเสียเงินจริงและทำให้ CI ไม่ deterministic) — ห้ามเรียกจากโค้ด production
 */
export const setAnthropicClientForTests = (fakeClient) => {
  testOverride = fakeClient;
};

export default getAnthropicClient;
