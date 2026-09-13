import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, cleanup } from './helpers/testApp.js';

after(cleanup);

// ดูรายงาน security review (Vuln 7): CSP เดิมปิดทั้งแอปเพราะ Swagger UI ที่ /docs ต้องใช้
// inline script/style — ตอนนี้ปิดเฉพาะ /docs เท่านั้น endpoint JSON อื่นยังมี CSP เป็น
// defense-in-depth
test('/health (JSON API) มี Content-Security-Policy header', async () => {
  const res = await api().get('/health');
  assert.ok(res.headers['content-security-policy']);
});

test('/docs (Swagger UI) ไม่มี Content-Security-Policy header (ต้องใช้ inline script/style)', async () => {
  const res = await api().get('/docs/');
  assert.equal(res.headers['content-security-policy'], undefined);
});
