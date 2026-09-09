import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

after(cleanup);

const get = (url, token) => api().get(url).set(authHeader(token));
const post = (url, token, body) =>
  api()
    .post(url)
    .set(authHeader(token))
    .send(body ?? {});

/** เปิดออเดอร์ใหม่ 1 ใบพร้อมโต๊ะว่างและเมนู 1 รายการ แล้วจ่ายเต็มจำนวน คืนออเดอร์ + payment ที่จ่าย */
const openAndPayOrder = async (waiterToken, cashierToken) => {
  const tablesRes = await get('/api/v1/tables?status=available', waiterToken);
  const table = tablesRes.body.data[0];
  assert.ok(table, 'ต้องมีโต๊ะว่างอย่างน้อย 1 โต๊ะสำหรับเทสต์นี้');

  const menuRes = await get('/api/v1/menu-items?availableOnly=true&limit=200', waiterToken);
  const menuItem = menuRes.body.data[0];

  const orderRes = await post('/api/v1/orders', waiterToken, {
    type: 'dine_in',
    tableId: table.id,
    guestCount: 1,
    items: [{ menuItemId: menuItem.id, quantity: 1, optionIds: [] }],
  });
  assert.equal(orderRes.status, 201, JSON.stringify(orderRes.body));
  const order = orderRes.body.data;

  const payRes = await post('/api/v1/payments', cashierToken, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });
  assert.equal(payRes.status, 201, JSON.stringify(payRes.body));
  return { order, payment: payRes.body.data.payment };
};

test('POST /payments/:id/refund — ผู้จัดการคืนเงินเต็มจำนวนได้ พร้อมบันทึกเหตุผล', async () => {
  const manager = await login('manager', 'manager123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { order, payment } = await openAndPayOrder(waiter.token, cashier.token);

  const res = await post(`/api/v1/payments/${payment.id}/refund`, manager.token, {
    amount: payment.amount,
    reason: 'ลูกค้าคืนอาหาร',
  });

  assert.equal(res.status, 201);
  assert.equal(res.body.data.amount, payment.amount);
  assert.equal(res.body.data.reason, 'ลูกค้าคืนอาหาร');
  assert.equal(res.body.data.paymentId, payment.id);
  assert.equal(res.body.data.orderId, order.id);
});

test('POST /payments/:id/refund — คืนเงินเกินยอดที่จ่ายไว้ต้องได้ 400', async () => {
  const manager = await login('manager', 'manager123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { payment } = await openAndPayOrder(waiter.token, cashier.token);

  const res = await post(`/api/v1/payments/${payment.id}/refund`, manager.token, {
    amount: payment.amount + 100,
    reason: 'ทดสอบคืนเกิน',
  });

  assert.equal(res.status, 400);
});

test('POST /payments/:id/refund — คืนซ้ำจนเกินยอดคงเหลือของ payment ต้องได้ 400', async () => {
  const manager = await login('manager', 'manager123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { payment } = await openAndPayOrder(waiter.token, cashier.token);
  const half = Math.round((payment.amount / 2) * 100) / 100;

  const first = await post(`/api/v1/payments/${payment.id}/refund`, manager.token, {
    amount: half,
    reason: 'คืนครั้งที่ 1',
  });
  assert.equal(first.status, 201);

  const second = await post(`/api/v1/payments/${payment.id}/refund`, manager.token, {
    amount: payment.amount,
    reason: 'คืนครั้งที่ 2 (เกินยอดคงเหลือ)',
  });
  assert.equal(second.status, 400);
});

test('POST /payments/:id/refund — แคชเชียร์คืนเงินไม่ได้ (RBAC 403, สงวนไว้เฉพาะ manager ขึ้นไป)', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { payment } = await openAndPayOrder(waiter.token, cashier.token);

  const res = await post(`/api/v1/payments/${payment.id}/refund`, cashier.token, {
    amount: payment.amount,
    reason: 'แคชเชียร์พยายามคืนเงินเอง',
  });

  assert.equal(res.status, 403);
});

test('GET /payments/order/:id/receipt — แสดงรายการคืนเงินและยอดรวมที่คืนไปแล้ว', async () => {
  const manager = await login('manager', 'manager123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { order, payment } = await openAndPayOrder(waiter.token, cashier.token);
  const partial = Math.round((payment.amount / 2) * 100) / 100;

  await post(`/api/v1/payments/${payment.id}/refund`, manager.token, {
    amount: partial,
    reason: 'คืนบางส่วน',
  });

  const res = await get(`/api/v1/payments/order/${order.id}/receipt`, cashier.token);

  assert.equal(res.status, 200);
  assert.equal(res.body.data.refunds.length, 1);
  assert.equal(res.body.data.refunds[0].amount, partial);
  assert.equal(res.body.data.refundedTotal, partial);
});

test('GET /reports/summary — หักยอดคืนเงินออกจากยอดขายสุทธิ', async () => {
  const manager = await login('manager', 'manager123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const { payment } = await openAndPayOrder(waiter.token, cashier.token);

  const before = await get('/api/v1/reports/summary', manager.token);
  const netBefore = before.body.data.netSales;
  const refundTotalBefore = before.body.data.refundTotal;

  await post(`/api/v1/payments/${payment.id}/refund`, manager.token, {
    amount: payment.amount,
    reason: 'คืนเต็มจำนวนเพื่อทดสอบรายงาน',
  });

  const after = await get('/api/v1/reports/summary', manager.token);

  // เทสต์อื่นในไฟล์นี้อาจคืนเงินไปแล้วก่อนหน้า (ยอดวันนี้สะสมรวมกัน) จึงเทียบเป็นส่วนต่าง
  // ก่อน/หลังของเทสต์นี้เอง ไม่เทียบค่าสัมบูรณ์
  assert.equal(
    Math.round((after.body.data.netSales + Number.EPSILON) * 100) / 100,
    Math.round((netBefore - payment.amount) * 100) / 100,
  );
  assert.equal(
    Math.round((after.body.data.refundTotal + Number.EPSILON) * 100) / 100,
    Math.round((refundTotalBefore + payment.amount) * 100) / 100,
  );
});
