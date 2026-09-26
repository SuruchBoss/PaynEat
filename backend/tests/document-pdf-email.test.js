// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after, afterEach, before } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';
import { getDb } from '../src/db/index.js';
import { setMailTransportForTests } from '../src/core/mailer.js';
import { bahtText, thaiDate, thaiDateTime } from '../src/core/thaiFormat.js';

// เอกสารลูกหนี้เป็น PDF + ส่งอีเมล (ดู docs/tickets/23-document-pdf-email.md, docs/DECISIONS.md #57)

after(cleanup);
afterEach(() => setMailTransportForTests(null));

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) =>
  api()
    .post(url)
    .set(authHeader(token))
    .send(body ?? {});
const patch = (url, token, body) =>
  api()
    .patch(url)
    .set(authHeader(token))
    .send(body ?? {});

/** supertest ไม่เก็บ body ของ application/pdf ให้เอง — อ่านเป็น Buffer */
const getPdf = (url, token) =>
  api()
    .get(url)
    .set(authHeader(token))
    .buffer(true)
    .parse((res, done) => {
      const chunks = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => done(null, Buffer.concat(chunks)));
    });

const pageCount = (buffer) => (buffer.toString('latin1').match(/\/Type \/Page\b/g) ?? []).length;

/** transport ปลอมที่จำอีเมลที่ถูกส่งไว้ตรวจ */
const fakeTransport = ({ fail = false } = {}) => {
  const sent = [];
  return {
    sent,
    sendMail: async (message) => {
      if (fail) throw new Error('535 Authentication failed');
      sent.push(message);
      return { messageId: `<test-${sent.length}@payneat.local>` };
    },
  };
};

let admin;
let manager;
let cashier;
let waiter;
let unitItem;

const uniq = () => `${Date.now()}${Math.round(Math.random() * 1e4)}`;

const newCreditCustomer = async (email) => {
  const created = await post('/api/v1/customers', cashier.token, {
    name: `บริษัท ลูกค้าส่ง-${uniq()} จำกัด`,
    phone: `08${uniq().slice(-8)}`,
  });
  const credit = await patch(`/api/v1/customers/${created.body.data.id}/credit`, manager.token, {
    creditLimit: 50000,
    creditTermDays: 30,
    taxId: '0105561234567',
    address: '123 ถนนสุขุมวิท แขวงคลองตัน เขตคลองเตย กรุงเทพมหานคร 10110',
    ...(email ? { email } : {}),
  });
  assert.equal(credit.status, 200, JSON.stringify(credit.body));
  return credit.body.data;
};

const creditSale = async (customerId, quantity = 10) => {
  const opened = await post('/api/v1/orders', cashier.token, {
    type: 'takeaway',
    customerId,
    items: [{ menuItemId: unitItem.id, quantity }],
  });
  const order = opened.body.data;
  const paid = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'credit',
    amount: order.total,
  });
  assert.equal(paid.status, 201, JSON.stringify(paid.body));
  return { order, payment: paid.body.data.payment };
};

const billingNote = async (customerId) => {
  const res = await post('/api/v1/receivables/billing-notes', cashier.token, { customerId });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data;
};

before(async () => {
  admin = await login('admin', 'admin123');
  manager = await login('manager', 'manager123');
  cashier = await login('cashier', 'cashier123');
  waiter = await login('waiter1', 'waiter123');
  const menu = await get('/api/v1/menu-items?limit=200', admin.token);
  unitItem = menu.body.data.find((item) => item.name === 'น้ำเปล่า');
  const shift = await get('/api/v1/shifts/current', cashier.token);
  if (!shift.body.data) await post('/api/v1/shifts', cashier.token, { openingCash: 1000 });
});

test('bahtText อ่านจำนวนเงินเป็นตัวอักษรตามแบบเอกสารไทย และวันที่เป็น พ.ศ. เวลากรุงเทพฯ', () => {
  assert.equal(bahtText(0), 'ศูนย์บาทถ้วน');
  assert.equal(bahtText(1), 'หนึ่งบาทถ้วน');
  assert.equal(bahtText(11), 'สิบเอ็ดบาทถ้วน');
  assert.equal(bahtText(21), 'ยี่สิบเอ็ดบาทถ้วน');
  assert.equal(bahtText(101), 'หนึ่งร้อยเอ็ดบาทถ้วน');
  assert.equal(bahtText(0.5), 'ห้าสิบสตางค์');
  assert.equal(bahtText(1234.5), 'หนึ่งพันสองร้อยสามสิบสี่บาทห้าสิบสตางค์');
  assert.equal(bahtText(20089.67), 'สองหมื่นแปดสิบเก้าบาทหกสิบเจ็ดสตางค์');
  assert.equal(bahtText(1_000_001), 'หนึ่งล้านหนึ่งบาทถ้วน');
  assert.equal(bahtText(12_500_000), 'สิบสองล้านห้าแสนบาทถ้วน');

  // วันครบกำหนดเป็นวันตามปฏิทิน ไม่แปลง timezone / เวลาใน SQLite เป็น UTC → เวลากรุงเทพฯ (+7)
  assert.equal(thaiDate('2026-09-30'), '30 ก.ย. 2569');
  assert.equal(thaiDate('2026-09-30 18:30:00'), '1 ต.ค. 2569');
  assert.equal(thaiDateTime('2026-09-30 18:30:00'), '1 ต.ค. 2569 01:30');
  assert.equal(thaiDate(null), '-');
});

test('ดาวน์โหลด PDF ได้ทุกชนิดเอกสาร (ใบวางบิล ใบเสร็จ ใบลดหนี้ ใบแจ้งดอกเบี้ย)', async () => {
  const customer = await newCreditCustomer();
  const sale = await creditSale(customer.id, 30);
  await creditSale(customer.id, 5);
  const note = await billingNote(customer.id);
  const receipt = await post('/api/v1/receivables/receipts', cashier.token, {
    customerId: customer.id,
    amount: 50,
    method: 'transfer',
    reference: 'KBank 0923',
  });
  const creditNote = await post('/api/v1/receivables/credit-notes', manager.token, {
    paymentId: sale.payment.id,
    amount: 20,
    reason: 'ของชำรุด',
  });
  await patch('/api/v1/settings', manager.token, { lateFeeAnnualRatePercent: 12 });
  getDb()
    .prepare("UPDATE payments SET due_date = date('now', '-40 days') WHERE id = ?")
    .run(sale.payment.id);
  const lateFee = await post('/api/v1/receivables/late-fees', manager.token, {
    customerId: customer.id,
  });
  assert.equal(lateFee.status, 201, JSON.stringify(lateFee.body));
  await patch('/api/v1/settings', manager.token, { lateFeeAnnualRatePercent: 0 });

  const documents = [
    ['billing-notes', note.id, note.noteNo],
    ['receipts', receipt.body.data.id, receipt.body.data.receiptNo],
    ['credit-notes', creditNote.body.data.id, creditNote.body.data.noteNo],
    ['late-fees', lateFee.body.data.id, lateFee.body.data.chargeNo],
  ];
  for (const [path, id, number] of documents) {
    const res = await getPdf(`/api/v1/receivables/${path}/${id}/pdf`, cashier.token);
    assert.equal(res.status, 200, `${path}: ${res.status}`);
    assert.equal(res.headers['content-type'], 'application/pdf');
    assert.match(res.headers['content-disposition'], new RegExp(`filename="${number}\\.pdf"`));
    assert.equal(res.headers['cache-control'], 'no-store');
    assert.equal(res.body.subarray(0, 5).toString(), '%PDF-');
    assert.equal(pageCount(res.body), 1, `${path} ควรพอดีหน้าเดียว`);
  }

  const waiterPdf = await getPdf(`/api/v1/receivables/billing-notes/${note.id}/pdf`, waiter.token);
  assert.equal(waiterPdf.status, 403);
  const missing = await getPdf('/api/v1/receivables/billing-notes/999999/pdf', cashier.token);
  assert.equal(missing.status, 404);
});

test('ใบวางบิลที่มีหลายบิลยาวเกินหน้าเดียวต่อหน้าใหม่ได้ และเอกสารที่ยกเลิกแล้วยังดาวน์โหลดได้', async () => {
  const customer = await newCreditCustomer();
  for (let index = 0; index < 40; index += 1) await creditSale(customer.id, 1);
  const note = await billingNote(customer.id);
  assert.equal(note.items.length, 40);
  const long = await getPdf(`/api/v1/receivables/billing-notes/${note.id}/pdf`, cashier.token);
  assert.equal(long.status, 200);
  assert.ok(pageCount(long.body) >= 2, 'บิล 40 รายการต้องต่อหน้าที่สอง');

  await post(`/api/v1/receivables/billing-notes/${note.id}/void`, manager.token, {
    reason: 'ออกผิด',
  });
  const voided = await getPdf(`/api/v1/receivables/billing-notes/${note.id}/pdf`, cashier.token);
  assert.equal(voided.status, 200, 'ยกเลิกแล้วยังโหลดเก็บเป็นหลักฐานได้');
});

test('ส่งอีเมล: ไม่ได้ตั้ง SMTP = 503 และหน้าตั้งค่าบอกว่าปิดอยู่', async () => {
  const settings = (await get('/api/v1/settings', cashier.token)).body.data;
  assert.equal(settings.emailEnabled, false);

  const customer = await newCreditCustomer('billing@example.com');
  await creditSale(customer.id);
  const note = await billingNote(customer.id);
  const res = await post(`/api/v1/receivables/billing-notes/${note.id}/email`, cashier.token);
  assert.equal(res.status, 503);
  assert.equal(res.body.error.code, 'MAIL_NOT_CONFIGURED');
});

test('ส่งใบวางบิลทางอีเมล: ถึงอีเมลลูกค้าพร้อม PDF แนบ บันทึกประวัติและ audit log', async () => {
  const transport = fakeTransport();
  setMailTransportForTests(transport);
  assert.equal((await get('/api/v1/settings', cashier.token)).body.data.emailEnabled, true);

  const customer = await newCreditCustomer('ap@soulbbq.example');
  assert.equal(customer.email, 'ap@soulbbq.example');
  await creditSale(customer.id, 20);
  const note = await billingNote(customer.id);

  const res = await post(`/api/v1/receivables/billing-notes/${note.id}/email`, cashier.token, {
    message: 'รบกวนชำระภายในสิ้นเดือนนะคะ',
  });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.equal(transport.sent.length, 1);
  const mail = transport.sent[0];
  assert.equal(mail.to, 'ap@soulbbq.example');
  assert.match(mail.subject, new RegExp(`ใบวางบิล ${note.noteNo}`));
  assert.match(mail.text, new RegExp(`เรียน ${customer.name}`));
  assert.match(mail.text, /รบกวนชำระภายในสิ้นเดือนนะคะ/);
  assert.equal(mail.attachments.length, 1);
  assert.equal(mail.attachments[0].filename, `${note.noteNo}.pdf`);
  assert.equal(mail.attachments[0].content.subarray(0, 5).toString(), '%PDF-');

  assert.equal(res.body.data.emails.length, 1);
  assert.equal(res.body.data.emails[0].to, 'ap@soulbbq.example');
  assert.ok(res.body.data.emails[0].sentByName);
  const again = await get(`/api/v1/receivables/billing-notes/${note.id}`, cashier.token);
  assert.equal(again.body.data.emails.length, 1);

  // ส่งให้ฝ่ายบัญชีอีกคนได้ ประวัติเรียงล่าสุดก่อน
  const other = await post(`/api/v1/receivables/billing-notes/${note.id}/email`, manager.token, {
    to: 'account@soulbbq.example',
  });
  assert.equal(other.status, 200);
  assert.equal(other.body.data.emails[0].to, 'account@soulbbq.example');
  assert.equal(transport.sent.length, 2);

  const logs = await get(
    '/api/v1/audit-logs?action=receivable.document_email&limit=5',
    admin.token,
  );
  assert.ok(logs.body.data.some((log) => log.summary.includes('account@soulbbq.example')));
});

test('ส่งอีเมล: ลูกค้าไม่มีอีเมล = ต้องระบุผู้รับ, เอกสารยกเลิกส่งไม่ได้, SMTP ล้ม = 502 ไม่บันทึกประวัติ', async () => {
  setMailTransportForTests(fakeTransport());
  const customer = await newCreditCustomer();
  await creditSale(customer.id);
  const note = await billingNote(customer.id);

  const noEmail = await post(`/api/v1/receivables/billing-notes/${note.id}/email`, cashier.token);
  assert.equal(noEmail.status, 400);
  assert.match(noEmail.body.error.message, /ยังไม่มีอีเมล/);

  const badEmail = await post(`/api/v1/receivables/billing-notes/${note.id}/email`, cashier.token, {
    to: 'not-an-email',
  });
  assert.equal(badEmail.status, 422);

  const byWaiter = await post(`/api/v1/receivables/billing-notes/${note.id}/email`, waiter.token, {
    to: 'a@b.example',
  });
  assert.equal(byWaiter.status, 403);

  setMailTransportForTests(fakeTransport({ fail: true }));
  const failed = await post(`/api/v1/receivables/billing-notes/${note.id}/email`, cashier.token, {
    to: 'a@b.example',
  });
  assert.equal(failed.status, 502);
  assert.equal(failed.body.error.code, 'MAIL_SEND_FAILED');
  const afterFail = await get(`/api/v1/receivables/billing-notes/${note.id}`, cashier.token);
  assert.equal(afterFail.body.data.emails.length, 0);

  setMailTransportForTests(fakeTransport());
  await post(`/api/v1/receivables/billing-notes/${note.id}/void`, manager.token, {
    reason: 'ออกผิด',
  });
  const voided = await post(`/api/v1/receivables/billing-notes/${note.id}/email`, cashier.token, {
    to: 'a@b.example',
  });
  assert.equal(voided.status, 409);
});

test('บันทึกอีเมลลูกค้าในบัญชีเครดิต: ไม่ส่งมา = คงค่าเดิม ส่ง "" = ล้างค่า', async () => {
  const customer = await newCreditCustomer('first@example.com');
  const keep = await patch(`/api/v1/customers/${customer.id}/credit`, manager.token, {
    creditLimit: 1000,
    creditTermDays: 15,
  });
  assert.equal(keep.body.data.email, 'first@example.com');
  const cleared = await patch(`/api/v1/customers/${customer.id}/credit`, manager.token, {
    creditLimit: 1000,
    creditTermDays: 15,
    email: '',
  });
  assert.equal(cleared.body.data.email, null);
  const invalid = await patch(`/api/v1/customers/${customer.id}/credit`, manager.token, {
    creditLimit: 1000,
    creditTermDays: 15,
    email: 'nope',
  });
  assert.equal(invalid.status, 422);
});
