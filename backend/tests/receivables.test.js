import test, { after, before } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';
import { getDb } from '../src/db/index.js';

// ขายเชื่อ / ลูกหนี้การค้า / ใบวางบิล (ดู docs/tickets/20-b2b-credit.md, docs/DECISIONS.md #50)

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
let waiter;
let unitItem;

/** ปัดเป็นสตางค์ — ยอดบิลมีค่าบริการ 10% + VAT 7% จึงไม่ใช่เลขกลม ลบกันตรง ๆ จะติดเศษทศนิยม */
const r2 = (value) => Math.round(value * 100) / 100;
const uniq = () => `${Date.now()}${Math.round(Math.random() * 1e4)}`;
const phone = () => `08${uniq().slice(-8)}`;

const newCreditCustomer = async ({ limit = 5000, term = 30 } = {}) => {
  const created = await post('/api/v1/customers', cashier.token, {
    name: `ร้านอาหารลูกค้าส่ง-${uniq()}`,
    phone: phone(),
  });
  const credit = await patch(`/api/v1/customers/${created.body.data.id}/credit`, manager.token, {
    creditLimit: limit,
    creditTermDays: term,
    taxId: '0105561234567',
    address: '1 ถนนทดสอบ กรุงเทพฯ',
  });
  assert.equal(credit.status, 200, JSON.stringify(credit.body));
  return credit.body.data;
};

/** เปิดบิลกลับบ้านให้ลูกค้ารายนี้ quantity จานของเมนูเดิม แล้วคืน order */
const openOrder = async (customerId, quantity = 1) => {
  const res = await post('/api/v1/orders', cashier.token, {
    type: 'takeaway',
    customerId,
    items: [{ menuItemId: unitItem.id, quantity }],
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data;
};

const payCredit = (order, token = cashier.token, extra = {}) =>
  post('/api/v1/payments', token, {
    orderId: order.id,
    method: 'credit',
    amount: order.total,
    ...extra,
  });

const statement = async (customerId) =>
  (await get(`/api/v1/receivables/customers/${customerId}`, cashier.token)).body.data;

const ensureOpenShift = async () => {
  const current = await get('/api/v1/shifts/current', cashier.token);
  if (current.body.data) return current.body.data;
  const opened = await post('/api/v1/shifts', cashier.token, { openingCash: 1000 });
  return opened.body.data;
};

const closeShift = async (shift, countedCash) =>
  patch(`/api/v1/shifts/${shift.id}/close`, cashier.token, { countedCash });

before(async () => {
  admin = await login('admin', 'admin123');
  manager = await login('manager', 'manager123');
  cashier = await login('cashier', 'cashier123');
  waiter = await login('waiter1', 'waiter123');
  const menu = await get('/api/v1/menu-items?limit=200', admin.token);
  // เมนูราคาง่าย ไม่มีตัวเลือกบังคับ ไม่ผูกวัตถุดิบ (น้ำเปล่า 20 บาท) — ยอดบิลคงที่ทุกครั้ง
  unitItem = menu.body.data.find((item) => item.name === 'น้ำเปล่า');
  assert.ok(unitItem);
  await ensureOpenShift();
});

test('ตั้งวงเงินเครดิตได้เฉพาะผู้จัดการขึ้นไป และถูกบันทึก audit log', async () => {
  const created = await post('/api/v1/customers', cashier.token, {
    name: `ลูกค้า-${uniq()}`,
    phone: phone(),
  });
  assert.equal(created.body.data.creditLimit, 0, 'ลูกค้าใหม่ยังไม่มีวงเงิน');

  const byCashier = await patch(`/api/v1/customers/${created.body.data.id}/credit`, cashier.token, {
    creditLimit: 1000,
    creditTermDays: 15,
  });
  assert.equal(byCashier.status, 403);

  const badTax = await patch(`/api/v1/customers/${created.body.data.id}/credit`, manager.token, {
    creditLimit: 1000,
    creditTermDays: 15,
    taxId: '12345',
  });
  assert.equal(badTax.status, 422);

  const ok = await patch(`/api/v1/customers/${created.body.data.id}/credit`, manager.token, {
    creditLimit: 1000,
    creditTermDays: 15,
  });
  assert.equal(ok.body.data.creditLimit, 1000);
  assert.equal(ok.body.data.creditTermDays, 15);
  assert.equal(ok.body.data.creditAvailable, 1000);

  const logs = await get('/api/v1/audit-logs?action=customer.credit_update&limit=5', admin.token);
  assert.ok(logs.body.data.some((log) => log.entityId === created.body.data.id));
});

test('ขายเชื่อ: ปิดบิลได้โดยไม่มีเงินเข้า ยอดกลายเป็นหนี้ พร้อมวันครบกำหนดตามเครดิตเทอม', async () => {
  const customer = await newCreditCustomer({ limit: 5000, term: 30 });
  const order = await openOrder(customer.id, 3);

  const res = await payCredit(order);
  assert.equal(res.status, 201, JSON.stringify(res.body));
  assert.equal(res.body.data.isFullyPaid, true);
  assert.equal(res.body.data.order.status, 'paid');
  assert.equal(res.body.data.payment.method, 'credit');

  const today = getDb().prepare("SELECT date('now', '+30 days') AS d").get().d;
  assert.equal(res.body.data.payment.dueDate, today);

  const s = await statement(customer.id);
  assert.equal(s.outstanding, order.total);
  assert.equal(s.available, 5000 - order.total);
  assert.equal(s.invoices.length, 1);
  assert.equal(s.invoices[0].orderCode, order.code);
  assert.equal(s.invoices[0].isOverdue, false);

  const detail = await get(`/api/v1/customers/${customer.id}`, cashier.token);
  assert.equal(detail.body.data.creditOutstanding, order.total);
});

test('ขายเชื่อถูกปฏิเสธ: ไม่ผูกลูกค้า, ลูกค้าไม่มีวงเงิน, เกินวงเงิน, พนักงานเสิร์ฟ, ใช้แต้ม', async () => {
  const anonymous = await post('/api/v1/orders', cashier.token, {
    type: 'takeaway',
    items: [{ menuItemId: unitItem.id, quantity: 1 }],
  });
  const noCustomer = await payCredit(anonymous.body.data);
  assert.equal(noCustomer.status, 400);

  const plain = await post('/api/v1/customers', cashier.token, {
    name: `ลูกค้าเงินสด-${uniq()}`,
    phone: phone(),
  });
  const noLimit = await payCredit(await openOrder(plain.body.data.id));
  assert.equal(noLimit.status, 409);
  assert.match(noLimit.body.error.message, /ยังไม่มีวงเงินเครดิต/);

  const small = await newCreditCustomer({ limit: 50 });
  const firstOrder = await openOrder(small.id, 2); // 47.08 บาทรวมค่าบริการ + VAT
  const first = await payCredit(firstOrder);
  assert.equal(first.status, 201);
  const over = await payCredit(await openOrder(small.id, 1)); // อีก 23.54 → เกิน 50
  assert.equal(over.status, 409);
  assert.match(
    over.body.error.message,
    new RegExp(`เกินวงเงินเครดิต.*ใช้ได้อีก ${r2(50 - firstOrder.total)} บาท`),
  );

  const credit = await newCreditCustomer();
  const byWaiter = await payCredit(await openOrder(credit.id), waiter.token);
  assert.equal(byWaiter.status, 403);

  const withPoints = await payCredit(await openOrder(credit.id), cashier.token, {
    pointsToRedeem: 1,
  });
  assert.equal(withPoints.status, 400);
});

test('รับชำระหนี้ตัดบิลเก่าสุดก่อน (FIFO) รับบางส่วนได้ รับเกินยอดค้างไม่ได้', async () => {
  const customer = await newCreditCustomer();
  const older = await openOrder(customer.id, 2);
  await payCredit(older);
  const newer = await openOrder(customer.id, 3);
  await payCredit(newer);

  const over = await post('/api/v1/receivables/receipts', cashier.token, {
    customerId: customer.id,
    amount: r2(older.total + newer.total + 1),
    method: 'transfer',
  });
  assert.equal(over.status, 400);
  assert.match(over.body.error.message, /เกินยอดค้าง/);

  const receipt = await post('/api/v1/receivables/receipts', cashier.token, {
    customerId: customer.id,
    amount: 50,
    method: 'transfer',
    reference: 'SCB-001',
  });
  assert.equal(receipt.status, 201, JSON.stringify(receipt.body));
  const buddhistYear = String(new Date().getFullYear() + 543).slice(-2);
  assert.match(receipt.body.data.receiptNo, new RegExp(`^RC${buddhistYear}-\\d{6}$`));
  assert.deepEqual(
    receipt.body.data.allocations.map((a) => [a.orderCode, a.amount]),
    [
      [older.code, older.total],
      [newer.code, r2(50 - older.total)],
    ],
  );

  const s = await statement(customer.id);
  assert.equal(s.outstanding, r2(older.total + newer.total - 50));
  const byCode = Object.fromEntries(s.invoices.map((inv) => [inv.orderCode, inv]));
  assert.equal(byCode[older.code].outstanding, 0);
  assert.equal(byCode[newer.code].outstanding, r2(newer.total - (50 - older.total)));
  assert.equal(s.receipts[0].receiptNo, receipt.body.data.receiptNo);
});

test('รับชำระหนี้เป็นเงินสดเข้าลิ้นชักของกะ: ปิดกะนับเงินตรงตามจริงได้ส่วนต่างศูนย์ และ Z-report แยกบรรทัด', async () => {
  const customer = await newCreditCustomer();
  const order = await openOrder(customer.id, 5); // 117.70 บาท — รับเงินสดบางส่วน 100
  await payCredit(order);

  // ปิดกะเดิมก่อนเปิดกะใหม่ ให้ยอดของกะนี้มีแค่รายการในเทสต์นี้
  const current = await get('/api/v1/shifts/current', cashier.token);
  if (current.body.data) await closeShift(current.body.data, 0);

  const noShift = await post('/api/v1/receivables/receipts', cashier.token, {
    customerId: customer.id,
    amount: 100,
    method: 'cash',
  });
  assert.equal(noShift.status, 409, 'เงินสดต้องมีกะเปิดอยู่ให้ผูก');

  const shift = (await post('/api/v1/shifts', cashier.token, { openingCash: 500 })).body.data;
  const cash = await post('/api/v1/receivables/receipts', cashier.token, {
    customerId: customer.id,
    amount: 100,
    method: 'cash',
  });
  assert.equal(cash.status, 201);
  assert.equal(cash.body.data.shiftId, shift.id);

  const z = await get(`/api/v1/reports/z-report/by-shift/${shift.id}`, cashier.token);
  assert.deepEqual(z.body.data.receivableReceipts, [{ method: 'cash', count: 1, amount: 100 }]);

  const closed = await closeShift(shift, 600);
  assert.equal(closed.body.data.expectedCash, 600);
  assert.equal(closed.body.data.variance, 0);

  await post('/api/v1/shifts', cashier.token, { openingCash: 1000 });
});

test('ยกเลิกใบเสร็จรับชำระ: ผู้จัดการเท่านั้น หนี้กลับมาค้าง และเงินสดของกะที่ปิดแล้วยกเลิกย้อนหลังไม่ได้', async () => {
  const customer = await newCreditCustomer();
  const order = await openOrder(customer.id, 2);
  await payCredit(order);
  const receipt = (
    await post('/api/v1/receivables/receipts', cashier.token, {
      customerId: customer.id,
      amount: order.total,
      method: 'qr',
    })
  ).body.data;
  assert.equal((await statement(customer.id)).outstanding, 0);

  const byCashier = await post(`/api/v1/receivables/receipts/${receipt.id}/void`, cashier.token, {
    reason: 'กดผิด',
  });
  assert.equal(byCashier.status, 403);

  const voided = await post(`/api/v1/receivables/receipts/${receipt.id}/void`, manager.token, {
    reason: 'โอนไม่เข้า',
  });
  assert.equal(voided.status, 200);
  assert.equal(voided.body.data.isVoided, true);
  assert.equal((await statement(customer.id)).outstanding, order.total, 'หนี้ต้องกลับมาค้าง');

  const again = await post(`/api/v1/receivables/receipts/${receipt.id}/void`, manager.token, {
    reason: 'ซ้ำ',
  });
  assert.equal(again.status, 409);

  // เงินสดที่รับไว้ในกะที่ปิดไปแล้ว — ยกเลิกไม่ได้เพราะยอดกะนั้นบันทึกปิดไปแล้ว
  const cash = (
    await post('/api/v1/receivables/receipts', cashier.token, {
      customerId: customer.id,
      amount: 10,
      method: 'cash',
    })
  ).body.data;
  const shift = (await get('/api/v1/shifts/current', cashier.token)).body.data;
  await closeShift(shift, 0);
  await post('/api/v1/shifts', cashier.token, { openingCash: 1000 });
  const lateVoid = await post(`/api/v1/receivables/receipts/${cash.id}/void`, manager.token, {
    reason: 'ย้อนหลัง',
  });
  assert.equal(lateVoid.status, 409);
  assert.match(lateVoid.body.error.message, /ปิดไปแล้ว/);
});

test('ใบวางบิล: รวบบิลค้างที่ยังไม่วางบิล, วางซ้ำไม่ได้, รับชำระตามใบวางบิล, ยกเลิกแล้ววางใหม่ได้', async () => {
  const customer = await newCreditCustomer({ term: 15 });
  const a = await openOrder(customer.id, 1);
  await payCredit(a);
  const b = await openOrder(customer.id, 2);
  await payCredit(b);

  const note = await post('/api/v1/receivables/billing-notes', cashier.token, {
    customerId: customer.id,
  });
  assert.equal(note.status, 201, JSON.stringify(note.body));
  const buddhistYear = String(new Date().getFullYear() + 543).slice(-2);
  assert.match(note.body.data.noteNo, new RegExp(`^BN${buddhistYear}-\\d{6}$`));
  assert.equal(note.body.data.total, r2(a.total + b.total));
  assert.equal(note.body.data.items.length, 2);
  assert.equal(note.body.data.status, 'open');
  assert.equal(note.body.data.customer.taxId, '0105561234567');
  assert.ok(note.body.data.store.name, 'หัวเอกสารต้องมีชื่อร้าน');

  const dup = await post('/api/v1/receivables/billing-notes', cashier.token, {
    customerId: customer.id,
  });
  assert.equal(dup.status, 409, 'ไม่มีบิลที่ยังไม่ได้วางแล้ว');

  // บิลใหม่หลังวางบิลไปแล้ว — รับชำระตามใบวางบิลต้องไม่ไปตัดบิลนอกใบ
  const c = await openOrder(customer.id, 4);
  await payCredit(c);
  const pay = await post('/api/v1/receivables/receipts', cashier.token, {
    customerId: customer.id,
    amount: r2(a.total + b.total),
    method: 'transfer',
    billingNoteId: note.body.data.id,
  });
  assert.equal(pay.status, 201, JSON.stringify(pay.body));
  assert.ok(pay.body.data.allocations.every((alloc) => alloc.orderCode !== c.code));

  const paidNote = await get(
    `/api/v1/receivables/billing-notes/${note.body.data.id}`,
    cashier.token,
  );
  assert.equal(paidNote.body.data.status, 'paid');
  assert.equal(paidNote.body.data.remaining, 0);

  const s = await statement(customer.id);
  assert.equal(s.outstanding, c.total);
  assert.equal(s.billingNotes[0].noteNo, note.body.data.noteNo);

  // ใบที่สองวางเฉพาะบิล c แล้วยกเลิก → บิล c วางใหม่ได้
  const second = await post('/api/v1/receivables/billing-notes', cashier.token, {
    customerId: customer.id,
  });
  assert.equal(second.body.data.items.length, 1);
  const voidByCashier = await post(
    `/api/v1/receivables/billing-notes/${second.body.data.id}/void`,
    cashier.token,
    { reason: 'พิมพ์ผิด' },
  );
  assert.equal(voidByCashier.status, 403);
  const voided = await post(
    `/api/v1/receivables/billing-notes/${second.body.data.id}/void`,
    manager.token,
    { reason: 'พิมพ์ผิด' },
  );
  assert.equal(voided.body.data.status, 'void');
  const third = await post('/api/v1/receivables/billing-notes', cashier.token, {
    customerId: customer.id,
    dueDate: '2099-01-31',
  });
  assert.equal(third.status, 201);
  assert.equal(third.body.data.dueDate, '2099-01-31');
});

test('คืนเงินบิลขายเชื่อ = ลดหนี้ ไม่แตะลิ้นชัก และลดได้ไม่เกินยอดที่ยังค้าง', async () => {
  const customer = await newCreditCustomer();
  const order = await openOrder(customer.id, 5);
  const payment = (await payCredit(order)).body.data.payment;

  await post('/api/v1/receivables/receipts', cashier.token, {
    customerId: customer.id,
    amount: 70,
    method: 'transfer',
  });
  const owed = r2(order.total - 70);

  const tooMuch = await post(`/api/v1/payments/${payment.id}/refund`, manager.token, {
    amount: r2(owed + 10),
    reason: 'ของเสีย',
  });
  assert.equal(tooMuch.status, 400);
  assert.match(tooMuch.body.error.message, new RegExp(`ค้างชำระอยู่ ${owed} บาท`));

  const ok = await post(`/api/v1/payments/${payment.id}/refund`, manager.token, {
    amount: owed,
    reason: 'ของเสีย',
  });
  assert.equal(ok.status, 201, JSON.stringify(ok.body));
  assert.equal((await statement(customer.id)).outstanding, 0);
});

test('อายุหนี้: บิลเกินกำหนดขึ้นเป็นยอดเกินกำหนดและอยู่ถูกช่องอายุหนี้', async () => {
  const customer = await newCreditCustomer();
  const order = await openOrder(customer.id, 2);
  const payment = (await payCredit(order)).body.data.payment;
  // ย้อนวันครบกำหนดไป 45 วันก่อน แทนการรอเวลาจริง
  getDb()
    .prepare("UPDATE payments SET due_date = date('now', '-45 days') WHERE id = ?")
    .run(payment.id);

  const s = await statement(customer.id);
  assert.equal(s.overdue, order.total);
  assert.equal(s.aging.days31to60, order.total);
  assert.equal(s.invoices[0].daysOverdue, 45);

  const list = await get('/api/v1/receivables/customers', cashier.token);
  const row = list.body.data.find((entry) => entry.customer.id === customer.id);
  assert.equal(row.overdue, order.total);
  assert.equal(list.body.data[0].overdue >= row.overdue, true, 'เกินกำหนดมากสุดขึ้นก่อน');

  const seeded = list.body.data.find((entry) => entry.customer.phone === '021234567');
  assert.ok(seeded, 'seed มีลูกค้าเครดิตตัวอย่างให้ลองทันที');
  assert.equal(seeded.creditLimit, 50000);
});

test('สิทธิ์: พนักงานเสิร์ฟดูลูกหนี้ไม่ได้ และทุกการกระทำเรื่องหนี้ถูกบันทึก audit log', async () => {
  const denied = await get('/api/v1/receivables/customers', waiter.token);
  assert.equal(denied.status, 403);

  const logs = await get('/api/v1/audit-logs?limit=100', admin.token);
  const actions = new Set(logs.body.data.map((log) => log.action));
  for (const action of [
    'receivable.receipt',
    'receivable.receipt_void',
    'receivable.billing_note',
    'receivable.billing_note_void',
  ]) {
    assert.ok(actions.has(action), `ต้องมี audit log ${action}`);
  }
});
