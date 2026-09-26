// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after, before } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';
import { getDb } from '../src/db/index.js';

// ดอกเบี้ยผิดนัดชำระ + ใบลดหนี้ (ดู docs/tickets/21-late-fees-credit-notes.md, docs/DECISIONS.md #55–#56)

after(cleanup);

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

let admin;
let manager;
let cashier;
let unitItem;

const satang = (baht) => Math.round(baht * 100);
const r2 = (value) => Math.round(value * 100) / 100;
const uniq = () => `${Date.now()}${Math.round(Math.random() * 1e4)}`;
/** ดอกเบี้ยแบบธรรมดา (สตางค์) สูตรเดียวกับ late-fee.service.js */
const interestOf = (principalBaht, rate, days) =>
  Math.round((satang(principalBaht) * rate * days) / (100 * 365)) / 100;
const today = () => getDb().prepare("SELECT date('now') AS d").get().d;
const daysAgo = (days) => getDb().prepare('SELECT date(?, ?) AS d').get('now', `-${days} days`).d;

const newCreditCustomer = async () => {
  const created = await post('/api/v1/customers', cashier.token, {
    name: `ร้านลูกค้าส่ง-${uniq()}`,
    phone: `08${uniq().slice(-8)}`,
  });
  const credit = await patch(`/api/v1/customers/${created.body.data.id}/credit`, manager.token, {
    creditLimit: 50000,
    creditTermDays: 30,
  });
  assert.equal(credit.status, 200, JSON.stringify(credit.body));
  return credit.body.data;
};

/** ขายเชื่อบิลน้ำเปล่า quantity ขวดให้ลูกค้า แล้วคืน { order, payment } */
const creditSale = async (customerId, quantity = 10) => {
  const opened = await post('/api/v1/orders', cashier.token, {
    type: 'takeaway',
    customerId,
    items: [{ menuItemId: unitItem.id, quantity }],
  });
  assert.equal(opened.status, 201, JSON.stringify(opened.body));
  const order = opened.body.data;
  const paid = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'credit',
    amount: order.total,
  });
  assert.equal(paid.status, 201, JSON.stringify(paid.body));
  return { order, payment: paid.body.data.payment };
};

const setDueDate = (paymentId, date) =>
  getDb().prepare('UPDATE payments SET due_date = ? WHERE id = ?').run(date, paymentId);

const setLateFee = (body) => patch('/api/v1/settings', manager.token, body);

const statement = async (customerId) =>
  (await get(`/api/v1/receivables/customers/${customerId}`, cashier.token)).body.data;

before(async () => {
  admin = await login('admin', 'admin123');
  manager = await login('manager', 'manager123');
  cashier = await login('cashier', 'cashier123');
  const menu = await get('/api/v1/menu-items?limit=200', admin.token);
  unitItem = menu.body.data.find((item) => item.name === 'น้ำเปล่า');
  assert.ok(unitItem);
  const shift = await get('/api/v1/shifts/current', cashier.token);
  if (!shift.body.data) await post('/api/v1/shifts', cashier.token, { openingCash: 1000 });
});

test('ตั้งอัตราดอกเบี้ยผิดนัด: เพดาน 15% ต่อปี แคชเชียร์ตั้งไม่ได้ และเปลี่ยนอัตราแล้วถูก audit', async () => {
  const initial = (await get('/api/v1/settings', cashier.token)).body.data;
  assert.equal(initial.lateFeeAnnualRatePercent, 0, 'ค่าเริ่มต้นคือไม่คิดดอกเบี้ย');
  assert.equal(initial.lateFeeGraceDays, 0);

  assert.equal((await setLateFee({ lateFeeAnnualRatePercent: 15.5 })).status, 422);
  assert.equal((await setLateFee({ lateFeeGraceDays: -1 })).status, 422);
  const byCashier = await patch('/api/v1/settings', cashier.token, {
    lateFeeAnnualRatePercent: 12,
  });
  assert.equal(byCashier.status, 403);

  const saved = await setLateFee({ lateFeeAnnualRatePercent: 12, lateFeeGraceDays: 5 });
  assert.equal(saved.status, 200, JSON.stringify(saved.body));
  assert.equal(saved.body.data.lateFeeAnnualRatePercent, 12);
  assert.equal(saved.body.data.lateFeeGraceDays, 5);

  const logs = await get('/api/v1/audit-logs?action=settings.update&limit=5', admin.token);
  assert.ok(logs.body.data.some((log) => log.summary.includes('ดอกเบี้ยผิดนัด 0% → 12%')));

  await setLateFee({ lateFeeAnnualRatePercent: 0, lateFeeGraceDays: 0 });
});

test('ยังไม่ตั้งอัตรา = ไม่คิดดอกเบี้ย แม้บิลจะเกินกำหนด', async () => {
  const customer = await newCreditCustomer();
  const { payment } = await creditSale(customer.id);
  setDueDate(payment.id, daysAgo(40));

  const preview = await get(
    `/api/v1/receivables/customers/${customer.id}/late-fee-preview`,
    cashier.token,
  );
  assert.equal(preview.status, 200);
  assert.equal(preview.body.data.items.length, 0);
  assert.equal(preview.body.data.total, 0);

  const create = await post('/api/v1/receivables/late-fees', manager.token, {
    customerId: customer.id,
  });
  assert.equal(create.status, 409);
  assert.match(create.body.error.message, /ยังไม่ได้ตั้งอัตราดอกเบี้ย/);
});

test('คิดดอกเบี้ย: เฉพาะบิลที่เลยวันผ่อนผัน นับถึงวันนี้ บวกเข้ายอดค้าง และกดซ้ำวันเดิมไม่ได้ดอกเบี้ยซ้ำ', async () => {
  await setLateFee({ lateFeeAnnualRatePercent: 12, lateFeeGraceDays: 5 });
  const customer = await newCreditCustomer();
  const late = await creditSale(customer.id, 50);
  const inGrace = await creditSale(customer.id, 5);
  await creditSale(customer.id, 5); // ยังไม่ถึงกำหนด (อีก 30 วัน)
  setDueDate(late.payment.id, daysAgo(35));
  setDueDate(inGrace.payment.id, daysAgo(3));

  // ครบกำหนด 35 วันก่อน + ผ่อนผัน 5 วัน → เริ่มนับวันที่ 6 หลังครบกำหนด ถึงวันนี้รวม 30 วัน
  const expected = interestOf(late.order.total, 12, 30);
  const preview = (
    await get(`/api/v1/receivables/customers/${customer.id}/late-fee-preview`, cashier.token)
  ).body.data;
  assert.equal(preview.items.length, 1, 'บิลที่ยังอยู่ในช่วงผ่อนผันต้องยังไม่ถูกคิด');
  assert.equal(preview.items[0].paymentId, late.payment.id);
  assert.equal(preview.items[0].days, 30);
  assert.equal(preview.items[0].periodFrom, daysAgo(29));
  assert.equal(preview.items[0].periodTo, today());
  assert.equal(preview.items[0].principal, late.order.total);
  assert.equal(preview.items[0].amount, expected);
  assert.equal(preview.total, expected);

  const byCashier = await post('/api/v1/receivables/late-fees', cashier.token, {
    customerId: customer.id,
  });
  assert.equal(byCashier.status, 403, 'เพิ่มหนี้ให้ลูกค้าต้องเป็นผู้จัดการขึ้นไป');

  const before = await statement(customer.id);
  const created = await post('/api/v1/receivables/late-fees', manager.token, {
    customerId: customer.id,
    note: 'ตามเงื่อนไขในใบวางบิล',
  });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  assert.match(created.body.data.chargeNo, /^LF\d{2}-\d{6}$/);
  assert.equal(created.body.data.total, expected);
  assert.equal(created.body.data.annualRate, 12);
  assert.equal(created.body.data.customer.id, customer.id);
  assert.ok(created.body.data.store.name);

  const after = await statement(customer.id);
  assert.equal(after.outstanding, r2(before.outstanding + expected));
  const invoice = after.invoices.find((row) => row.paymentId === late.payment.id);
  assert.equal(invoice.interest, expected);
  assert.equal(invoice.interestThrough, today());
  assert.equal(invoice.outstanding, r2(late.order.total + expected));
  assert.equal(after.lateFees.length, 1);
  assert.equal(after.lateFees[0].chargeNo, created.body.data.chargeNo);

  const again = await post('/api/v1/receivables/late-fees', manager.token, {
    customerId: customer.id,
  });
  assert.equal(again.status, 409, 'คิดไปถึงวันนี้แล้ว กดซ้ำต้องไม่ได้ดอกเบี้ยซ้ำ');

  const logs = await get('/api/v1/audit-logs?action=receivable.late_fee&limit=5', admin.token);
  assert.ok(logs.body.data.some((log) => log.entityId === created.body.data.id));
  await setLateFee({ lateFeeAnnualRatePercent: 0, lateFeeGraceDays: 0 });
});

test('รอบถัดไปนับต่อจากวันที่คิดไปแล้ว และคิดจากเงินต้นที่ยังค้างเท่านั้น (เงินที่จ่ายตัดดอกเบี้ยก่อน)', async () => {
  await setLateFee({ lateFeeAnnualRatePercent: 10, lateFeeGraceDays: 0 });
  const customer = await newCreditCustomer();
  const sale = await creditSale(customer.id, 50);
  setDueDate(sale.payment.id, daysAgo(20));

  const first = await post('/api/v1/receivables/late-fees', manager.token, {
    customerId: customer.id,
  });
  assert.equal(first.status, 201, JSON.stringify(first.body));
  assert.equal(first.body.data.items[0].days, 20);
  const firstInterest = first.body.data.total;

  // ลูกค้าจ่ายมาครึ่งบิล — ตัดดอกเบี้ยก่อน ยอดที่ยังค้างทั้งหมดจึงเป็นเงินต้น
  const paidAmount = r2(sale.order.total / 2);
  const receipt = await post('/api/v1/receivables/receipts', cashier.token, {
    customerId: customer.id,
    amount: paidAmount,
    method: 'transfer',
  });
  assert.equal(receipt.status, 201, JSON.stringify(receipt.body));
  const owed = r2(sale.order.total + firstInterest - paidAmount);

  // ย้อนวันที่คิดดอกเบี้ยรอบก่อนไป 10 วัน = ผ่านไปแล้ว 10 วันนับจากรอบก่อน
  getDb()
    .prepare('UPDATE ar_charge_items SET period_to = ? WHERE charge_id = ?')
    .run(daysAgo(10), first.body.data.id);
  const preview = (
    await get(`/api/v1/receivables/customers/${customer.id}/late-fee-preview`, cashier.token)
  ).body.data;
  assert.equal(preview.items.length, 1);
  assert.equal(preview.items[0].periodFrom, daysAgo(9));
  assert.equal(preview.items[0].days, 10);
  assert.equal(
    preview.items[0].principal,
    owed,
    'เงินต้นค้าง = ยอดค้าง เมื่อดอกเบี้ยถูกจ่ายหมดแล้ว',
  );
  assert.equal(preview.items[0].amount, interestOf(owed, 10, 10));
  await setLateFee({ lateFeeAnnualRatePercent: 0 });
});

test('รับชำระตัดดอกเบี้ยด้วย ยกเลิกใบแจ้งดอกเบี้ยที่จ่ายแล้วไม่ได้จนกว่าจะยกเลิกใบเสร็จ', async () => {
  await setLateFee({ lateFeeAnnualRatePercent: 15, lateFeeGraceDays: 0 });
  const customer = await newCreditCustomer();
  const sale = await creditSale(customer.id, 50);
  setDueDate(sale.payment.id, daysAgo(60));
  const charge = (
    await post('/api/v1/receivables/late-fees', manager.token, { customerId: customer.id })
  ).body.data;
  const owed = r2(sale.order.total + charge.total);

  const tooMuch = await post('/api/v1/receivables/receipts', cashier.token, {
    customerId: customer.id,
    amount: r2(owed + 1),
    method: 'transfer',
  });
  assert.equal(tooMuch.status, 400, 'รับเกินยอดค้าง (รวมดอกเบี้ย) ไม่ได้');

  const receipt = await post('/api/v1/receivables/receipts', cashier.token, {
    customerId: customer.id,
    amount: owed,
    method: 'transfer',
    reference: 'โอน KBank',
  });
  assert.equal(receipt.status, 201, JSON.stringify(receipt.body));
  assert.equal((await statement(customer.id)).outstanding, 0);

  const blocked = await post(`/api/v1/receivables/late-fees/${charge.id}/void`, manager.token, {
    reason: 'ยกเว้นให้ลูกค้าประจำ',
  });
  assert.equal(blocked.status, 409);
  assert.match(blocked.body.error.message, /ยกเลิกใบเสร็จรับชำระก่อน/);

  await post(`/api/v1/receivables/receipts/${receipt.body.data.id}/void`, manager.token, {
    reason: 'โอนผิดบัญชี',
  });
  const byCashier = await post(`/api/v1/receivables/late-fees/${charge.id}/void`, cashier.token, {
    reason: 'x',
  });
  assert.equal(byCashier.status, 403);

  const voided = await post(`/api/v1/receivables/late-fees/${charge.id}/void`, manager.token, {
    reason: 'ยกเว้นให้ลูกค้าประจำ',
  });
  assert.equal(voided.status, 200, JSON.stringify(voided.body));
  assert.equal(voided.body.data.isVoided, true);
  assert.equal(voided.body.data.voidReason, 'ยกเว้นให้ลูกค้าประจำ');
  assert.equal((await statement(customer.id)).outstanding, sale.order.total);

  const twice = await post(`/api/v1/receivables/late-fees/${charge.id}/void`, manager.token, {
    reason: 'ซ้ำ',
  });
  assert.equal(twice.status, 409);

  // ใบที่ยกเลิกไม่นับเป็น "คิดไปแล้ว" — คิดใหม่ได้ตั้งแต่วันแรกที่เลยกำหนด
  const preview = (
    await get(`/api/v1/receivables/customers/${customer.id}/late-fee-preview`, cashier.token)
  ).body.data;
  assert.equal(preview.items[0].days, 60);
  await setLateFee({ lateFeeAnnualRatePercent: 0 });
});

test('ลดหนี้บิลขายเชื่อออกใบลดหนี้อัตโนมัติ: มูลค่าเดิม มูลค่าที่ถูกต้อง ผลต่าง VAT และเลขใบกำกับภาษีเดิม', async () => {
  const customer = await newCreditCustomer();
  const sale = await creditSale(customer.id, 20);
  const taxInvoice = await post(`/api/v1/tax-invoices/order/${sale.order.id}`, cashier.token, {
    invoiceType: 'full',
    customerName: customer.name,
    customerAddress: '1 ถนนทดสอบ',
  });
  assert.equal(taxInvoice.status, 201, JSON.stringify(taxInvoice.body));

  const byCashier = await post('/api/v1/receivables/credit-notes', cashier.token, {
    paymentId: sale.payment.id,
    amount: 10,
    reason: 'ของชำรุด',
  });
  assert.equal(byCashier.status, 403);

  const first = await post('/api/v1/receivables/credit-notes', manager.token, {
    paymentId: sale.payment.id,
    amount: 40,
    reason: 'ของชำรุด 2 ขวด',
  });
  assert.equal(first.status, 201, JSON.stringify(first.body));
  const note = first.body.data;
  assert.match(note.noteNo, /^CN\d{2}-\d{6}$/);
  assert.equal(note.originalAmount, sale.order.total);
  assert.equal(note.previousCredited, 0);
  assert.equal(note.amount, 40);
  assert.equal(note.correctAmount, r2(sale.order.total - 40));
  const expectedVat = Math.round((4000 * satang(sale.order.vat)) / satang(sale.order.total)) / 100;
  assert.equal(note.vatAmount, expectedVat);
  assert.equal(note.baseAmount, r2(40 - expectedVat));
  assert.equal(note.taxInvoiceNo, taxInvoice.body.data.runningNumber);
  assert.equal(note.reason, 'ของชำรุด 2 ขวด');
  assert.equal(note.orderCode, sale.order.code);
  assert.equal(note.customer.id, customer.id);

  // คืนเงินผ่าน endpoint เดิมก็ได้ใบลดหนี้เหมือนกัน และรู้ว่าเคยลดหนี้ไปแล้วเท่าไร
  const second = await post(`/api/v1/payments/${sale.payment.id}/refund`, manager.token, {
    amount: 20,
    reason: 'ส่งของขาด 1 ขวด',
  });
  assert.equal(second.status, 201, JSON.stringify(second.body));
  assert.ok(second.body.data.creditNoteId);
  assert.match(second.body.data.creditNoteNo, /^CN\d{2}-\d{6}$/);
  const secondNote = (
    await get(`/api/v1/receivables/credit-notes/${second.body.data.creditNoteId}`, cashier.token)
  ).body.data;
  assert.equal(secondNote.previousCredited, 40);
  assert.equal(secondNote.correctAmount, r2(sale.order.total - 60));

  const s = await statement(customer.id);
  assert.equal(s.outstanding, r2(sale.order.total - 60));
  assert.deepEqual(
    s.creditNotes.map((row) => row.noteNo).sort(),
    [note.noteNo, secondNote.noteNo].sort(),
  );

  const logs = await get('/api/v1/audit-logs?action=receivable.credit_note&limit=5', admin.token);
  assert.ok(logs.body.data.some((log) => log.entityId === note.id));
});

test('ใบลดหนี้: ใช้ได้เฉพาะบิลขายเชื่อ และลดเกินยอดค้างไม่ได้โดยไม่มีเอกสารค้างในระบบ', async () => {
  const opened = await post('/api/v1/orders', cashier.token, {
    type: 'takeaway',
    items: [{ menuItemId: unitItem.id, quantity: 1 }],
  });
  const cash = await post('/api/v1/payments', cashier.token, {
    orderId: opened.body.data.id,
    method: 'cash',
    amount: opened.body.data.total,
    received: opened.body.data.total,
  });
  assert.equal(cash.status, 201, JSON.stringify(cash.body));
  const cashNote = await post('/api/v1/receivables/credit-notes', manager.token, {
    paymentId: cash.body.data.payment.id,
    amount: 1,
    reason: 'ทดสอบ',
  });
  assert.equal(cashNote.status, 400);
  assert.match(cashNote.body.error.message, /เฉพาะบิลขายเชื่อ/);

  const cashRefund = await post(
    `/api/v1/payments/${cash.body.data.payment.id}/refund`,
    manager.token,
    {
      amount: 1,
      reason: 'ทอนผิด',
    },
  );
  assert.equal(cashRefund.status, 201);
  assert.equal(cashRefund.body.data.creditNoteId, null, 'คืนเงินบิลเงินสดไม่ต้องมีใบลดหนี้');

  const missing = await post('/api/v1/receivables/credit-notes', manager.token, {
    paymentId: 999999,
    amount: 1,
    reason: 'ทดสอบ',
  });
  assert.equal(missing.status, 404);

  const customer = await newCreditCustomer();
  const sale = await creditSale(customer.id, 5);
  const countBefore = getDb().prepare('SELECT COUNT(*) AS c FROM credit_notes').get().c;
  const tooMuch = await post('/api/v1/receivables/credit-notes', manager.token, {
    paymentId: sale.payment.id,
    amount: r2(sale.order.total + 1),
    reason: 'เกิน',
  });
  assert.equal(tooMuch.status, 400);
  assert.equal(getDb().prepare('SELECT COUNT(*) AS c FROM credit_notes').get().c, countBefore);

  assert.equal((await get('/api/v1/receivables/credit-notes/999999', cashier.token)).status, 404);
});
