import test, { after, before } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';
import { getDb } from '../src/db/index.js';

// แต้มสะสมของบิลขายเชื่อได้ตอน "รับชำระครบ" ไม่ใช่ตอนลงบัญชี (ดู docs/DECISIONS.md #59)

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
let water;
let earnRate;

const uniq = () => `${Date.now()}${Math.round(Math.random() * 1e4)}`;
const satang = (baht) => Math.round(baht * 100);
const pointsFor = (baht) => Math.floor(satang(baht) / satang(earnRate));

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

const openOrder = async (customerId, quantity = 20) => {
  const opened = await post('/api/v1/orders', cashier.token, {
    type: 'takeaway',
    customerId,
    items: [{ menuItemId: water.id, quantity }],
  });
  assert.equal(opened.status, 201, JSON.stringify(opened.body));
  return opened.body.data;
};

const pay = async (orderId, body) => {
  const paid = await post('/api/v1/payments', cashier.token, { orderId, ...body });
  assert.equal(paid.status, 201, JSON.stringify(paid.body));
  return paid.body.data;
};

const creditSale = async (customerId, quantity = 20) => {
  const order = await openOrder(customerId, quantity);
  const paid = await pay(order.id, { method: 'credit', amount: order.total });
  return { order, payment: paid.payment };
};

const collect = async (customerId, amount, method = 'transfer') => {
  const receipt = await post('/api/v1/receivables/receipts', cashier.token, {
    customerId,
    amount,
    method,
  });
  assert.equal(receipt.status, 201, JSON.stringify(receipt.body));
  return receipt.body.data;
};

const balanceOf = async (customerId) =>
  (await get(`/api/v1/customers/${customerId}`, cashier.token)).body.data.pointsBalance;

const earnedOn = async (orderId) =>
  (await get(`/api/v1/orders/${orderId}`, cashier.token)).body.data.pointsEarned;

const lastAudit = (action) =>
  getDb().prepare('SELECT * FROM audit_logs WHERE action = ? ORDER BY id DESC LIMIT 1').get(action);

before(async () => {
  admin = await login('admin', 'admin123');
  manager = await login('manager', 'manager123');
  cashier = await login('cashier', 'cashier123');
  const menu = await get('/api/v1/menu-items?limit=200', admin.token);
  water = menu.body.data.find((item) => item.name === 'น้ำเปล่า');
  assert.ok(water);
  earnRate = (await get('/api/v1/settings', cashier.token)).body.data.pointsEarnRateBaht;
  const shift = await get('/api/v1/shifts/current', cashier.token);
  if (!shift.body.data) await post('/api/v1/shifts', cashier.token, { openingCash: 1000 });
});

test('บิลเงินสดยังได้แต้มทันทีตอนปิดบิลเหมือนเดิม', async () => {
  const customer = await newCreditCustomer();
  const order = await openOrder(customer.id);
  await pay(order.id, { method: 'cash', amount: order.total, received: order.total });
  assert.ok(pointsFor(order.total) > 0);
  assert.equal(await balanceOf(customer.id), pointsFor(order.total));
  assert.equal(await earnedOn(order.id), pointsFor(order.total));
});

test('ขายเชื่อ: ยังไม่ได้แต้มตอนลงบัญชี/รับชำระบางส่วน ได้ครบตอนรับชำระหนี้ครบ', async () => {
  const customer = await newCreditCustomer();
  const { order } = await creditSale(customer.id);
  assert.equal(await balanceOf(customer.id), 0, 'ยังไม่ได้เงิน = ยังไม่ได้แต้ม');
  assert.equal(await earnedOn(order.id), 0);

  await collect(customer.id, 100);
  assert.equal(await balanceOf(customer.id), 0, 'จ่ายบางส่วนยังไม่ได้แต้ม');

  await collect(customer.id, Math.round((order.total - 100) * 100) / 100);
  assert.equal(await balanceOf(customer.id), pointsFor(order.total));
  assert.equal(await earnedOn(order.id), pointsFor(order.total));
  const audit = lastAudit('receivable.receipt');
  assert.equal(JSON.parse(audit.metadata_json).pointsEarned, pointsFor(order.total));
});

test('ใบเสร็จเดียวตัดหลายบิล: ได้แต้มเฉพาะบิลที่ชำระครบ', async () => {
  const customer = await newCreditCustomer();
  const first = await creditSale(customer.id, 20);
  const second = await creditSale(customer.id, 30);
  // ตัดบิลเก่าสุดก่อน: ครบใบแรก + บางส่วนของใบที่สอง
  await collect(customer.id, first.order.total + 50);
  assert.equal(await earnedOn(first.order.id), pointsFor(first.order.total));
  assert.equal(await earnedOn(second.order.id), 0);
  assert.equal(await balanceOf(customer.id), pointsFor(first.order.total));
});

test('ยกเลิกใบเสร็จที่ปิดยอด = ดึงแต้มคืน รับชำระใหม่ได้แต้มกลับมาโดยไม่ได้ซ้ำ', async () => {
  const customer = await newCreditCustomer();
  const { order } = await creditSale(customer.id);
  const receipt = await collect(customer.id, order.total);
  assert.equal(await balanceOf(customer.id), pointsFor(order.total));

  const voided = await post(`/api/v1/receivables/receipts/${receipt.id}/void`, manager.token, {
    reason: 'โอนเข้าผิดบัญชี',
  });
  assert.equal(voided.status, 200, JSON.stringify(voided.body));
  assert.equal(await balanceOf(customer.id), 0);
  assert.equal(await earnedOn(order.id), 0);
  const audit = JSON.parse(lastAudit('receivable.receipt_void').metadata_json);
  assert.equal(audit.pointsRevoked, pointsFor(order.total));
  assert.equal(audit.pointsNotRecovered, 0);

  await collect(customer.id, order.total);
  assert.equal(await balanceOf(customer.id), pointsFor(order.total));
});

test('ลูกค้าใช้แต้มไปแล้วก่อนใบเสร็จถูกยกเลิก: ดึงคืนเท่าที่มี ยอดแต้มไม่ติดลบ และไม่ได้แต้มซ้ำ', async () => {
  const customer = await newCreditCustomer();
  const { order } = await creditSale(customer.id);
  const receipt = await collect(customer.id, order.total);
  const earned = pointsFor(order.total);
  const spend = earned - 2;

  // ใช้แต้มแลกส่วนลดบิลเงินสดเล็ก ๆ อีกใบ (น้ำ 1 ขวด ไม่ได้แต้มเพิ่ม) เหลือ 2 แต้ม
  const otherOrder = await openOrder(customer.id, 1);
  await pay(otherOrder.id, {
    method: 'cash',
    amount: otherOrder.total,
    received: otherOrder.total,
    pointsToRedeem: spend,
  });
  const afterSpend = await balanceOf(customer.id);
  assert.equal(pointsFor(otherOrder.total), 0);
  assert.equal(afterSpend, 2);

  await post(`/api/v1/receivables/receipts/${receipt.id}/void`, manager.token, {
    reason: 'เช็คเด้ง',
  });
  const audit = JSON.parse(lastAudit('receivable.receipt_void').metadata_json);
  const balance = await balanceOf(customer.id);
  assert.ok(balance >= 0);
  assert.equal(audit.pointsRevoked + audit.pointsNotRecovered, earned);
  assert.equal(audit.pointsRevoked, afterSpend, 'ดึงคืนได้เท่าที่ลูกค้ามี');
  assert.equal(balance, 0);
  assert.equal(await earnedOn(order.id), audit.pointsNotRecovered);

  // รับชำระใหม่: ได้เฉพาะส่วนที่ถูกดึงคืนไป ไม่ได้ทั้งก้อนซ้ำ
  await collect(customer.id, order.total);
  assert.equal(await balanceOf(customer.id), audit.pointsRevoked);
  assert.equal(await earnedOn(order.id), earned);
});

test('ลดหนี้แล้วจ่ายส่วนที่เหลือ: แต้มคิดจากยอดสุทธิ — ลดหนี้ทั้งบิลไม่ได้แต้มเลย', async () => {
  const customer = await newCreditCustomer();
  const { order, payment } = await creditSale(customer.id, 30);
  const credited = await post('/api/v1/receivables/credit-notes', manager.token, {
    paymentId: payment.id,
    amount: 200,
    reason: 'ของชำรุด',
  });
  assert.equal(credited.status, 201, JSON.stringify(credited.body));
  assert.equal(await balanceOf(customer.id), 0);
  await collect(customer.id, Math.round((order.total - 200) * 100) / 100);
  assert.equal(await balanceOf(customer.id), pointsFor(order.total - 200));

  const other = await newCreditCustomer();
  const returned = await creditSale(other.id);
  const all = await post('/api/v1/receivables/credit-notes', manager.token, {
    paymentId: returned.payment.id,
    amount: returned.order.total,
    reason: 'ลูกค้าคืนของทั้งบิล',
  });
  assert.equal(all.status, 201, JSON.stringify(all.body));
  assert.equal(await balanceOf(other.id), 0, 'ไม่ได้จ่ายอะไรเลย = ไม่ได้แต้ม');
});

test('ดอกเบี้ยผิดนัดค้างอยู่ = ยังไม่ครบ ยกเว้นดอกเบี้ยแล้วได้แต้มจากยอดบิล ไม่รวมดอกเบี้ย', async () => {
  const customer = await newCreditCustomer();
  const { order, payment } = await creditSale(customer.id);
  await patch('/api/v1/settings', manager.token, {
    lateFeeAnnualRatePercent: 12,
    lateFeeGraceDays: 0,
  });
  getDb()
    .prepare("UPDATE payments SET due_date = date('now', '-60 days') WHERE id = ?")
    .run(payment.id);
  const fee = await post('/api/v1/receivables/late-fees', manager.token, {
    customerId: customer.id,
  });
  assert.equal(fee.status, 201, JSON.stringify(fee.body));
  assert.ok(fee.body.data.total > 0);

  // จ่ายเท่ายอดบิล เหลือค้างเท่าดอกเบี้ย = ยังไม่ครบ ยังไม่ได้แต้ม
  await collect(customer.id, order.total);
  const statement = (await get(`/api/v1/receivables/customers/${customer.id}`, cashier.token)).body
    .data;
  assert.equal(statement.outstanding, fee.body.data.total);
  assert.equal(await balanceOf(customer.id), 0);

  const waived = await post(
    `/api/v1/receivables/late-fees/${fee.body.data.id}/void`,
    manager.token,
    { reason: 'ยกเว้นดอกเบี้ยให้ลูกค้าประจำ' },
  );
  assert.equal(waived.status, 200, JSON.stringify(waived.body));
  assert.equal(await balanceOf(customer.id), pointsFor(order.total), 'ดอกเบี้ยไม่นับเป็นยอดซื้อ');
  assert.equal(
    JSON.parse(lastAudit('receivable.late_fee_void').metadata_json).pointsEarned,
    pointsFor(order.total),
  );

  await patch('/api/v1/settings', manager.token, { lateFeeAnnualRatePercent: 0 });
});

test('บิลแยกจ่าย ขายเชื่อบางส่วน: ชำระหนี้ครบก่อนจ่ายส่วนที่เหลือ ได้แต้มตอนบิลปิด', async () => {
  const customer = await newCreditCustomer();
  const order = await openOrder(customer.id);
  await pay(order.id, { method: 'credit', amount: 100 });
  await collect(customer.id, 100);
  assert.equal(await balanceOf(customer.id), 0, 'บิลยังไม่ปิด');
  const rest = Math.round((order.total - 100) * 100) / 100;
  await pay(order.id, { method: 'cash', amount: rest, received: rest });
  assert.equal(await balanceOf(customer.id), pointsFor(order.total));
});
