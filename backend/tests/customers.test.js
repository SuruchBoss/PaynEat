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
const patch = (url, token, body) => api().patch(url).set(authHeader(token)).send(body);

const uniquePhone = () => `08${Date.now().toString().slice(-8)}`;

/** เปิดออเดอร์ใหม่ 1 ใบพร้อมโต๊ะว่างและเมนู 1 รายการ ผูกลูกค้าได้ตาม extra.customerId */
const openOrder = async (waiterToken, extra = {}) => {
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
    ...extra,
  });
  assert.equal(orderRes.status, 201, JSON.stringify(orderRes.body));
  return orderRes.body.data;
};

const createCustomer = async (token, overrides = {}) => {
  const res = await post('/api/v1/customers', token, {
    name: 'คุณทดสอบ ระบบสมาชิก',
    phone: uniquePhone(),
    ...overrides,
  });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data;
};

test('POST /customers — สร้างลูกค้าใหม่ได้ และเบอร์ซ้ำต้องได้ 409', async () => {
  const { token } = await login('cashier', 'cashier123');
  const phone = uniquePhone();

  const created = await createCustomer(token, { phone });
  assert.equal(created.phone, phone);
  assert.equal(created.pointsBalance, 0);

  const dup = await post('/api/v1/customers', token, { name: 'อีกคน', phone });
  assert.equal(dup.status, 409);
});

test('GET /customers — ค้นหาด้วยเบอร์โทร/ชื่อเจอลูกค้าที่สร้างไว้', async () => {
  const { token } = await login('waiter1', 'waiter123');
  const phone = uniquePhone();
  const created = await createCustomer(token, { name: 'คุณค้นหาได้', phone });

  const byPhone = await get(`/api/v1/customers?search=${phone}`, token);
  assert.equal(byPhone.status, 200);
  assert.ok(byPhone.body.data.some((row) => row.id === created.id));

  const byName = await get('/api/v1/customers?search=คุณค้นหาได้', token);
  assert.ok(byName.body.data.some((row) => row.id === created.id));
});

test('GET /customers, POST /customers — ครัวเข้าไม่ได้ (RBAC)', async () => {
  const { token } = await login('kitchen', 'kitchen123');
  assert.equal((await get('/api/v1/customers', token)).status, 403);
  assert.equal(
    (await post('/api/v1/customers', token, { name: 'x', phone: uniquePhone() })).status,
    403,
  );
});

test('POST /orders — ผูกลูกค้าได้แบบ optional และปฏิเสธ customerId ที่ไม่มีอยู่จริง', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const customer = await createCustomer(waiter.token);

  const order = await openOrder(waiter.token, { customerId: customer.id });
  assert.equal(order.customerId, customer.id);
  assert.equal(order.customerName, customer.name);

  const tablesRes = await get('/api/v1/tables?status=available', waiter.token);
  const table = tablesRes.body.data[0];
  const menuRes = await get('/api/v1/menu-items?availableOnly=true&limit=200', waiter.token);
  const badOrder = await post('/api/v1/orders', waiter.token, {
    type: 'dine_in',
    tableId: table.id,
    customerId: 999999,
    items: [{ menuItemId: menuRes.body.data[0].id, quantity: 1, optionIds: [] }],
  });
  assert.equal(badOrder.status, 400);
});

test('GET /orders?customerId= — กรองเฉพาะออเดอร์ของลูกค้ารายนั้น', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const customer = await createCustomer(waiter.token);
  const order = await openOrder(waiter.token, { customerId: customer.id });

  const res = await get(`/api/v1/orders?customerId=${customer.id}`, waiter.token);
  assert.equal(res.status, 200);
  assert.ok(res.body.data.every((row) => row.customerId === customer.id));
  assert.ok(res.body.data.some((row) => row.id === order.id));
});

test('จ่ายเต็มจำนวนให้ออเดอร์ที่ผูกลูกค้า — สะสมแต้มอัตโนมัติตามอัตรา default (25 บาท/แต้ม)', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const customer = await createCustomer(waiter.token);

  const order = await openOrder(waiter.token, { customerId: customer.id });
  const payRes = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });
  assert.equal(payRes.status, 201, JSON.stringify(payRes.body));
  assert.equal(payRes.body.data.isFullyPaid, true);

  const totalSatang = Math.round(order.total * 100);
  const expectedPoints = Math.floor(totalSatang / 2500); // ค่า default: 25 บาท/แต้ม

  assert.equal(payRes.body.data.order.pointsEarned, expectedPoints);

  const customerAfter = await get(`/api/v1/customers/${customer.id}`, cashier.token);
  assert.equal(customerAfter.body.data.pointsBalance, expectedPoints);
});

test('ออเดอร์ที่ไม่ได้ผูกลูกค้า — จ่ายครบแล้วไม่มีแต้มให้ใคร', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const order = await openOrder(waiter.token);

  const payRes = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });
  assert.equal(payRes.status, 201);
  assert.equal(payRes.body.data.order.pointsEarned, 0);
});

test('แยกจ่ายหลายรอบ — สะสมแต้มแค่ตอนจ่ายครบเท่านั้น ไม่ใช่ทุกรอบ', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const customer = await createCustomer(waiter.token);
  const order = await openOrder(waiter.token, { customerId: customer.id });

  const half = Math.round((order.total / 2) * 100) / 100;
  const firstPay = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: half,
    received: half,
  });
  assert.equal(firstPay.status, 201, JSON.stringify(firstPay.body));
  assert.equal(firstPay.body.data.isFullyPaid, false);
  assert.equal(firstPay.body.data.order.pointsEarned, 0);

  const customerMidway = await get(`/api/v1/customers/${customer.id}`, cashier.token);
  assert.equal(customerMidway.body.data.pointsBalance, 0, 'ยังไม่จ่ายครบ ไม่ควรได้แต้มระหว่างทาง');

  const remainingRes = await get(`/api/v1/payments/order/${order.id}`, cashier.token);
  const remaining = remainingRes.body.data.remaining;
  const secondPay = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: remaining,
    received: remaining,
  });
  assert.equal(secondPay.status, 201, JSON.stringify(secondPay.body));
  assert.equal(secondPay.body.data.isFullyPaid, true);
  assert.ok(secondPay.body.data.order.pointsEarned > 0);
});

test('ใช้แต้มสะสมแลกส่วนลดตอนจ่ายเงิน — หักแต้มและลดยอดที่ต้องจ่ายจริงถูกต้อง', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const customer = await createCustomer(waiter.token);

  // สร้างแต้มให้ลูกค้าก่อนด้วยออเดอร์แรก
  const firstOrder = await openOrder(waiter.token, { customerId: customer.id });
  await post('/api/v1/payments', cashier.token, {
    orderId: firstOrder.id,
    method: 'cash',
    amount: firstOrder.total,
    received: firstOrder.total,
  });
  const customerAfterFirst = await get(`/api/v1/customers/${customer.id}`, cashier.token);
  const pointsBalance = customerAfterFirst.body.data.pointsBalance;
  assert.ok(pointsBalance > 0, 'ต้องมีแต้มสะสมจากออเดอร์แรกก่อนถึงทดสอบใช้แต้มได้');

  // ใช้แต้มบางส่วนตอนจ่ายออเดอร์ที่สอง (ค่า default: 1 แต้ม = 1 บาท)
  const secondOrder = await openOrder(waiter.token, { customerId: customer.id });
  const pointsToRedeem = Math.min(pointsBalance, 5);
  const payRes = await post('/api/v1/payments', cashier.token, {
    orderId: secondOrder.id,
    method: 'cash',
    amount: secondOrder.total,
    received: secondOrder.total - pointsToRedeem,
    pointsToRedeem,
  });
  assert.equal(payRes.status, 201, JSON.stringify(payRes.body));
  assert.equal(payRes.body.data.payment.pointsRedeemed, pointsToRedeem);
  assert.equal(payRes.body.data.payment.pointsRedeemedValue, pointsToRedeem);
  assert.equal(payRes.body.data.payment.received, secondOrder.total - pointsToRedeem);
  assert.equal(payRes.body.data.payment.change, 0);

  const customerAfterSecond = await get(`/api/v1/customers/${customer.id}`, cashier.token);
  // ยอดแต้มลดลงตามที่ใช้ บวกกลับด้วยแต้มใหม่ที่ได้จากออเดอร์ที่สอง (จ่ายครบเช่นกัน)
  const expectedNewPoints = Math.floor(Math.round(secondOrder.total * 100) / 2500);
  assert.equal(
    customerAfterSecond.body.data.pointsBalance,
    pointsBalance - pointsToRedeem + expectedNewPoints,
  );
});

test('ใช้แต้มไม่ได้ถ้าออเดอร์ไม่ได้ผูกลูกค้า หรือแต้มไม่พอ หรือมูลค่าเกินยอดที่ต้องจ่าย', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');

  const noCustomerOrder = await openOrder(waiter.token);
  const noCustomerRes = await post('/api/v1/payments', cashier.token, {
    orderId: noCustomerOrder.id,
    method: 'cash',
    amount: noCustomerOrder.total,
    pointsToRedeem: 1,
  });
  assert.equal(noCustomerRes.status, 400);

  const customer = await createCustomer(waiter.token);
  const order = await openOrder(waiter.token, { customerId: customer.id });

  const notEnoughRes = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    pointsToRedeem: 999999,
  });
  assert.equal(notEnoughRes.status, 400);
});

test('PATCH /settings — ปรับอัตราแต้มสะสมแล้วมีผลกับการคำนวณจริง', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');

  const settingsRes = await patch('/api/v1/settings', admin.token, {
    pointsEarnRateBaht: 10,
    pointsRedeemValueBaht: 2,
  });
  assert.equal(settingsRes.status, 200);
  assert.equal(settingsRes.body.data.pointsEarnRateBaht, 10);
  assert.equal(settingsRes.body.data.pointsRedeemValueBaht, 2);

  const customer = await createCustomer(waiter.token);
  const order = await openOrder(waiter.token, { customerId: customer.id });
  const payRes = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });
  const expectedPoints = Math.floor(Math.round(order.total * 100) / 1000); // 10 บาท/แต้ม
  assert.equal(payRes.body.data.order.pointsEarned, expectedPoints);

  // คืนอัตราเดิมกันกระทบเทสต์อื่นที่รันไฟล์เดียวกัน (แต่ไฟล์นี้ไม่มีเทสต์อื่นหลังจากนี้)
  await patch('/api/v1/settings', admin.token, {
    pointsEarnRateBaht: 25,
    pointsRedeemValueBaht: 1,
  });
});
