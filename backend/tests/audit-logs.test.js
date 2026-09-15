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
const del = (url, token) => api().delete(url).set(authHeader(token));

const uniqueUsername = (prefix) =>
  `${prefix}${Date.now().toString().slice(-8)}${Math.random().toString(36).slice(2, 6)}`;

/** เปิดออเดอร์ใหม่ 1 ใบพร้อมโต๊ะว่างและเมนู 1 รายการ (ยังไม่ส่งครัว) */
const openOrder = async (waiterToken) => {
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
  return orderRes.body.data;
};

/** ค้นหา log ล่าสุดของ action นี้ที่ผูกกับ entityId (admin เท่านั้นที่ดูได้) */
const findLatestLog = async (adminToken, action, entityId) => {
  const res = await get(
    `/api/v1/audit-logs?action=${action}&entityId=${entityId}&limit=5`,
    adminToken,
  );
  assert.equal(res.status, 200, JSON.stringify(res.body));
  return res.body.data[0];
};

test('GET /audit-logs — พนักงานเสิร์ฟ/ผู้จัดการเข้าดูไม่ได้ สงวนไว้เฉพาะ admin', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const manager = await login('manager', 'manager123');

  assert.equal((await get('/api/v1/audit-logs', waiter.token)).status, 403);
  assert.equal((await get('/api/v1/audit-logs', manager.token)).status, 403);
});

test('GET /audit-logs — admin ดูได้ พร้อม meta สำหรับแบ่งหน้า', async () => {
  const admin = await login('admin', 'admin123');
  const res = await get('/api/v1/audit-logs?limit=5&page=1', admin.token);

  assert.equal(res.status, 200);
  assert.ok(Array.isArray(res.body.data));
  assert.equal(res.body.meta.page, 1);
  assert.equal(res.body.meta.limit, 5);
  assert.equal(typeof res.body.meta.total, 'number');
});

test('POST /orders/:id/cancel — ยกเลิกออเดอร์ต้องถูกบันทึก audit log พร้อมเหตุผลและผู้ทำ', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const manager = await login('manager', 'manager123');
  const order = await openOrder(waiter.token);

  const cancelRes = await post(`/api/v1/orders/${order.id}/cancel`, manager.token, {
    reason: 'ลูกค้ายกเลิกก่อนส่งครัว',
  });
  assert.equal(cancelRes.status, 200, JSON.stringify(cancelRes.body));

  const log = await findLatestLog(admin.token, 'order.cancel', order.id);
  assert.ok(log, 'ต้องมี audit log สำหรับการยกเลิกออเดอร์นี้');
  assert.equal(log.entityType, 'order');
  assert.equal(log.reason, 'ลูกค้ายกเลิกก่อนส่งครัว');
  assert.equal(log.actorName, 'สมชาย (ผู้จัดการ)');
  assert.match(log.summary, new RegExp(order.code));
});

test('PATCH /orders/:id/items/:itemId/status — void รายการหลังครัวทำแล้วต้องถูก log แต่ยกเลิกตอนยัง pending ไม่ log', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const kitchen = await login('kitchen', 'kitchen123');
  const manager = await login('manager', 'manager123');

  // เคสที่ 1: ยกเลิกตอนยัง pending (ยังไม่ส่งครัว) — ไม่ถือว่าเสี่ยง ไม่ต้อง log
  const orderPending = await openOrder(waiter.token);
  const pendingItem = orderPending.items[0];
  const cancelPending = await patch(
    `/api/v1/orders/${orderPending.id}/items/${pendingItem.id}/status`,
    waiter.token,
    { status: 'cancelled' },
  );
  assert.equal(cancelPending.status, 200, JSON.stringify(cancelPending.body));
  const pendingLogRes = await get(
    `/api/v1/audit-logs?action=order_item.void&entityId=${pendingItem.id}`,
    admin.token,
  );
  assert.equal(pendingLogRes.body.data.length, 0, 'ยกเลิกตอนยัง pending ไม่ควร log');

  // เคสที่ 2: ส่งครัวแล้วครัวเริ่มทำ (cooking) แล้วผู้จัดการ void — ต้อง log
  const orderCooking = await openOrder(waiter.token);
  const cookingItem = orderCooking.items[0];
  await post(`/api/v1/orders/${orderCooking.id}/send-to-kitchen`, waiter.token);
  await patch(`/api/v1/orders/${orderCooking.id}/items/${cookingItem.id}/status`, kitchen.token, {
    status: 'cooking',
  });
  const voidRes = await patch(
    `/api/v1/orders/${orderCooking.id}/items/${cookingItem.id}/status`,
    manager.token,
    { status: 'cancelled' },
  );
  assert.equal(voidRes.status, 200, JSON.stringify(voidRes.body));

  const log = await findLatestLog(admin.token, 'order_item.void', cookingItem.id);
  assert.ok(log, 'ต้องมี audit log สำหรับการ void รายการหลังครัวทำแล้ว');
  assert.equal(log.entityType, 'order_item');
  assert.equal(log.actorName, 'สมชาย (ผู้จัดการ)');
  assert.match(log.summary, new RegExp(orderCooking.code));
});

test('POST /orders/:id/discount — ให้/ยกเลิกส่วนลดต้องถูกบันทึก audit log', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const order = await openOrder(waiter.token);

  const discountRes = await post(`/api/v1/orders/${order.id}/discount`, cashier.token, {
    type: 'percent',
    value: 10,
  });
  assert.equal(discountRes.status, 200, JSON.stringify(discountRes.body));

  const log = await findLatestLog(admin.token, 'order.discount', order.id);
  assert.ok(log, 'ต้องมี audit log สำหรับการให้ส่วนลด');
  assert.equal(log.entityType, 'order');
  assert.equal(log.actorName, 'พี่แอน (แคชเชียร์)');
  assert.equal(log.metadata.newType, 'percent');
});

test('PATCH /users/:id — ปิดการใช้งานและเปลี่ยนสิทธิ์บัญชีต้องถูกบันทึกแยกกัน', async () => {
  const admin = await login('admin', 'admin123');
  const created = await post('/api/v1/users', admin.token, {
    name: 'พนักงานทดสอบ audit log',
    username: uniqueUsername('audit'),
    password: 'test1234',
    role: 'waiter',
  });
  const userId = created.body.data.id;

  const roleRes = await patch(`/api/v1/users/${userId}`, admin.token, { role: 'cashier' });
  assert.equal(roleRes.status, 200);
  const roleLog = await findLatestLog(admin.token, 'user.role_change', userId);
  assert.ok(roleLog, 'ต้องมี audit log สำหรับการเปลี่ยนสิทธิ์');
  assert.equal(roleLog.metadata.previousRole, 'waiter');
  assert.equal(roleLog.metadata.newRole, 'cashier');

  const deactivateRes = await patch(`/api/v1/users/${userId}`, admin.token, { isActive: false });
  assert.equal(deactivateRes.status, 200);
  const deactivateLog = await findLatestLog(admin.token, 'user.deactivate', userId);
  assert.ok(deactivateLog, 'ต้องมี audit log สำหรับการปิดการใช้งานบัญชี');

  // แก้แค่ชื่อเฉยๆ ไม่ถือว่าเสี่ยง ไม่ต้อง log
  await patch(`/api/v1/users/${userId}`, admin.token, { isActive: true });
  const beforeRename = await get(`/api/v1/audit-logs?entityId=${userId}&limit=50`, admin.token);
  const countBefore = beforeRename.body.data.length;
  await patch(`/api/v1/users/${userId}`, admin.token, { name: 'ชื่อใหม่เฉยๆ' });
  const afterRename = await get(`/api/v1/audit-logs?entityId=${userId}&limit=50`, admin.token);
  assert.equal(afterRename.body.data.length, countBefore, 'แก้ชื่อเฉยๆ ไม่ควรเพิ่ม log ใหม่');
});

test('POST /users/:id/reset-password และ DELETE /users/:id — ต้องถูกบันทึก audit log', async () => {
  const admin = await login('admin', 'admin123');
  const created = await post('/api/v1/users', admin.token, {
    name: 'จะถูกรีเซ็ตรหัสแล้วลบ',
    username: uniqueUsername('rmme'),
    password: 'test1234',
    role: 'waiter',
  });
  const userId = created.body.data.id;

  const resetRes = await post(`/api/v1/users/${userId}/reset-password`, admin.token, {
    password: 'newpassword1',
  });
  assert.equal(resetRes.status, 200);
  const resetLog = await findLatestLog(admin.token, 'user.password_reset', userId);
  assert.ok(resetLog, 'ต้องมี audit log สำหรับการตั้งรหัสผ่านใหม่');

  const deleteRes = await del(`/api/v1/users/${userId}`, admin.token);
  assert.equal(deleteRes.status, 204);
  const deleteLog = await findLatestLog(admin.token, 'user.delete', userId);
  assert.ok(deleteLog, 'ต้องมี audit log สำหรับการลบบัญชี แม้บัญชีจะถูกลบไปแล้ว');
  assert.equal(deleteLog.actorUserId, admin.user.id);
  assert.equal(deleteLog.actorName, 'ผู้ดูแลระบบ');
});

test('PATCH /settings — แก้ VAT/ค่าบริการต้อง log แต่แก้ชื่อร้านเฉยๆ ไม่ต้อง log', async () => {
  const admin = await login('admin', 'admin123');
  const before = await get('/api/v1/settings', admin.token);

  const vatRes = await patch('/api/v1/settings', admin.token, {
    vatRate: before.body.data.vatRate === 0.07 ? 0.08 : 0.07,
  });
  assert.equal(vatRes.status, 200);
  const listRes = await get('/api/v1/audit-logs?action=settings.update&limit=1', admin.token);
  assert.equal(listRes.status, 200);
  assert.ok(listRes.body.data.length >= 1, 'ต้องมี audit log สำหรับการแก้ VAT');
  const countAfterVat = listRes.body.meta.total;

  await patch('/api/v1/settings', admin.token, { storeName: 'ร้านทดสอบ audit log' });
  const listRes2 = await get('/api/v1/audit-logs?action=settings.update&limit=1', admin.token);
  assert.equal(listRes2.body.meta.total, countAfterVat, 'แก้ชื่อร้านเฉยๆ ไม่ควรเพิ่ม log ใหม่');
});

test('POST /payments/:id/refund — คืนเงินต้องถูกบันทึก audit log', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const manager = await login('manager', 'manager123');

  const order = await openOrder(waiter.token);
  const payRes = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });
  assert.equal(payRes.status, 201);
  const payment = payRes.body.data.payment;

  const refundRes = await post(`/api/v1/payments/${payment.id}/refund`, manager.token, {
    amount: payment.amount,
    reason: 'ลูกค้าคืนอาหาร (ทดสอบ audit log)',
  });
  assert.equal(refundRes.status, 201);
  const refundId = refundRes.body.data.id;

  const log = await findLatestLog(admin.token, 'payment.refund', refundId);
  assert.ok(log, 'ต้องมี audit log สำหรับการคืนเงิน');
  assert.equal(log.entityType, 'refund');
  assert.equal(log.reason, 'ลูกค้าคืนอาหาร (ทดสอบ audit log)');
});

test('POST /tax-invoices/order/:id/void — ยกเลิกใบกำกับภาษีต้องถูกบันทึก audit log', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');

  const order = await openOrder(waiter.token);
  await post(`/api/v1/orders/${order.id}/send-to-kitchen`, waiter.token);
  const payRes = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'qr',
    amount: order.total,
  });
  assert.equal(payRes.status, 201, JSON.stringify(payRes.body));

  const issueRes = await post(`/api/v1/tax-invoices/order/${order.id}`, cashier.token, {
    invoiceType: 'abbreviated',
  });
  assert.equal(issueRes.status, 201, JSON.stringify(issueRes.body));
  const invoiceId = issueRes.body.data.id;

  const voidRes = await post(`/api/v1/tax-invoices/order/${order.id}/void`, admin.token, {
    reason: 'ทดสอบ audit log',
  });
  assert.equal(voidRes.status, 200, JSON.stringify(voidRes.body));

  const log = await findLatestLog(admin.token, 'tax_invoice.void', invoiceId);
  assert.ok(log, 'ต้องมี audit log สำหรับการยกเลิกใบกำกับภาษี');
  assert.equal(log.entityType, 'tax_invoice');
  assert.equal(log.reason, 'ทดสอบ audit log');
});

// ดู docs/tickets/13-order-audit-trail.md — audit ระดับ "ใครกดสั่ง/แก้ไขออเดอร์" สำหรับ
// financial audit และผู้จัดการร้าน ไม่ใช่แค่เหตุการณ์เสี่ยงต่อการทุจริตเหมือนกลุ่มด้านบน

test('POST /orders — เปิดออเดอร์ใหม่ต้องถูกบันทึก audit log พร้อมชื่อพนักงานเสิร์ฟที่กดสั่ง', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const order = await openOrder(waiter.token);

  const log = await findLatestLog(admin.token, 'order.create', order.id);
  assert.ok(log, 'ต้องมี audit log สำหรับการเปิดออเดอร์ใหม่');
  assert.equal(log.entityType, 'order');
  assert.match(log.summary, new RegExp(order.code));
  assert.equal(log.metadata.itemCount, 1);
});

test('POST /orders/:id/items — เพิ่มรายการเข้าออเดอร์ต้องถูกบันทึก audit log', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const order = await openOrder(waiter.token);

  const menuRes = await get('/api/v1/menu-items?availableOnly=true&limit=200', waiter.token);
  const menuItem = menuRes.body.data[0];

  const addRes = await post(`/api/v1/orders/${order.id}/items`, waiter.token, {
    items: [{ menuItemId: menuItem.id, quantity: 2, optionIds: [] }],
  });
  assert.equal(addRes.status, 201, JSON.stringify(addRes.body));

  const log = await findLatestLog(admin.token, 'order.item.add', order.id);
  assert.ok(log, 'ต้องมี audit log สำหรับการเพิ่มรายการ');
  assert.equal(log.metadata.items.length, 1);
  assert.equal(log.metadata.items[0].quantity, 2);
});

test('PATCH /orders/:id/items/:itemId — แก้ไขจำนวนต้อง log แต่แก้แค่โน้ตไม่ log', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const order = await openOrder(waiter.token);
  const item = order.items[0];

  // แก้แค่โน้ตเฉยๆ ไม่ถือว่าเป็นการแก้ไขที่กระทบยอดเงิน ไม่ต้อง log
  const noteRes = await patch(`/api/v1/orders/${order.id}/items/${item.id}`, waiter.token, {
    note: 'ไม่เผ็ด',
  });
  assert.equal(noteRes.status, 200, JSON.stringify(noteRes.body));
  const noteLogRes = await get(
    `/api/v1/audit-logs?action=order.item.edit&entityId=${item.id}`,
    admin.token,
  );
  assert.equal(noteLogRes.body.data.length, 0, 'แก้แค่โน้ตไม่ควร log');

  // แก้จำนวนต้อง log
  const qtyRes = await patch(`/api/v1/orders/${order.id}/items/${item.id}`, waiter.token, {
    quantity: 3,
  });
  assert.equal(qtyRes.status, 200, JSON.stringify(qtyRes.body));

  const log = await findLatestLog(admin.token, 'order.item.edit', item.id);
  assert.ok(log, 'ต้องมี audit log สำหรับการแก้ไขจำนวน');
  assert.equal(log.entityType, 'order_item');
  assert.equal(log.metadata.previousQuantity, 1);
  assert.equal(log.metadata.newQuantity, 3);
});

test('DELETE /orders/:id/items/:itemId — ลบรายการต้องถูกบันทึก audit log', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const order = await openOrder(waiter.token);
  const item = order.items[0];

  const delRes = await del(`/api/v1/orders/${order.id}/items/${item.id}`, waiter.token);
  assert.equal(delRes.status, 200, JSON.stringify(delRes.body));

  const log = await findLatestLog(admin.token, 'order.item.remove', order.id);
  assert.ok(log, 'ต้องมี audit log สำหรับการลบรายการ');
  assert.equal(log.metadata.itemName, item.name);
});

test('PATCH /orders/:id/move-table — ย้ายโต๊ะต้องถูกบันทึก audit log', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const order = await openOrder(waiter.token);

  const tablesRes = await get('/api/v1/tables?status=available', waiter.token);
  const destination = tablesRes.body.data[0];
  assert.ok(destination, 'ต้องมีโต๊ะว่างอีกโต๊ะสำหรับย้าย');

  const moveRes = await patch(`/api/v1/orders/${order.id}/move-table`, waiter.token, {
    tableId: destination.id,
  });
  assert.equal(moveRes.status, 200, JSON.stringify(moveRes.body));

  const log = await findLatestLog(admin.token, 'order.move_table', order.id);
  assert.ok(log, 'ต้องมี audit log สำหรับการย้ายโต๊ะ');
  assert.equal(log.metadata.toTableId, destination.id);
});

test('POST /orders/:id/merge — รวมบิลต้องถูกบันทึก audit log', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const target = await openOrder(waiter.token);
  const source = await openOrder(waiter.token);

  const mergeRes = await post(`/api/v1/orders/${target.id}/merge`, waiter.token, {
    sourceOrderId: source.id,
  });
  assert.equal(mergeRes.status, 200, JSON.stringify(mergeRes.body));

  const log = await findLatestLog(admin.token, 'order.merge', target.id);
  assert.ok(log, 'ต้องมี audit log สำหรับการรวมบิล');
  assert.equal(log.metadata.sourceOrderCode, source.code);
  assert.equal(log.metadata.targetOrderCode, target.code);
});
