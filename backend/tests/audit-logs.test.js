// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

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

// ดู docs/tickets/14-financial-audit-trail.md — audit ระดับ "บัญชี/การเงิน" (แก้ราคาเมนู/
// โปรโมชัน/สต๊อกวัตถุดิบ) ต่างจากกลุ่มบนสุด (ป้องกันทุจริต) และกลุ่มก่อนหน้า (ใครสั่ง/แก้ไขออเดอร์)

test('PATCH /menu-items/:id — แก้ราคาต้อง log แต่แก้แค่ชื่อเฉยๆ ไม่ log', async () => {
  const admin = await login('admin', 'admin123');
  const category = await post('/api/v1/categories', admin.token, {
    name: `ทดสอบ audit-${Date.now()}`,
  });
  const menuItem = await post('/api/v1/menu-items', admin.token, {
    categoryId: category.body.data.id,
    name: 'เมนูทดสอบแก้ราคา',
    price: 100,
  });
  assert.equal(menuItem.status, 201, JSON.stringify(menuItem.body));
  const itemId = menuItem.body.data.id;

  // แก้แค่ชื่อเฉยๆ ไม่กระทบราคา ไม่ต้อง log
  const renameRes = await patch(`/api/v1/menu-items/${itemId}`, admin.token, {
    name: 'เมนูทดสอบแก้ราคา (เปลี่ยนชื่อ)',
  });
  assert.equal(renameRes.status, 200, JSON.stringify(renameRes.body));
  const renameLogRes = await get(
    `/api/v1/audit-logs?action=menu.price_change&entityId=${itemId}`,
    admin.token,
  );
  assert.equal(renameLogRes.body.data.length, 0, 'แก้แค่ชื่อไม่ควร log');

  // แก้ราคาต้อง log
  const priceRes = await patch(`/api/v1/menu-items/${itemId}`, admin.token, { price: 120 });
  assert.equal(priceRes.status, 200, JSON.stringify(priceRes.body));

  const log = await findLatestLog(admin.token, 'menu.price_change', itemId);
  assert.ok(log, 'ต้องมี audit log สำหรับการแก้ราคาเมนู');
  assert.equal(log.entityType, 'menu_item');
  assert.equal(log.metadata.previousPrice, 100);
  assert.equal(log.metadata.newPrice, 120);

  // ส่งราคาเดิมซ้ำ (ไม่เปลี่ยนจริง) ไม่ควร log เพิ่ม
  const beforeSamePrice = await get(
    `/api/v1/audit-logs?action=menu.price_change&entityId=${itemId}&limit=50`,
    admin.token,
  );
  await patch(`/api/v1/menu-items/${itemId}`, admin.token, { price: 120 });
  const afterSamePrice = await get(
    `/api/v1/audit-logs?action=menu.price_change&entityId=${itemId}&limit=50`,
    admin.token,
  );
  assert.equal(
    afterSamePrice.body.data.length,
    beforeSamePrice.body.data.length,
    'ส่งราคาเดิมซ้ำไม่ควรเพิ่ม log ใหม่',
  );
});

test('POST/PATCH/DELETE /promotions — สร้าง/แก้ไข/ลบโปรโมชันต้องถูกบันทึก audit log ครบ', async () => {
  const admin = await login('admin', 'admin123');
  const manager = await login('manager', 'manager123');

  const createRes = await post('/api/v1/promotions', manager.token, {
    name: `โปรโมชันทดสอบ audit-${Date.now()}`,
    type: 'percent',
    value: 15,
    conditions: {},
  });
  assert.equal(createRes.status, 201, JSON.stringify(createRes.body));
  const promotionId = createRes.body.data.id;

  const createLog = await findLatestLog(admin.token, 'promotion.create', promotionId);
  assert.ok(createLog, 'ต้องมี audit log สำหรับการสร้างโปรโมชัน');
  assert.equal(createLog.entityType, 'promotion');
  assert.equal(createLog.actorName, 'สมชาย (ผู้จัดการ)');

  const updateRes = await patch(`/api/v1/promotions/${promotionId}`, manager.token, {
    value: 20,
  });
  assert.equal(updateRes.status, 200, JSON.stringify(updateRes.body));
  const updateLog = await findLatestLog(admin.token, 'promotion.update', promotionId);
  assert.ok(updateLog, 'ต้องมี audit log สำหรับการแก้ไขโปรโมชัน');

  const deleteRes = await del(`/api/v1/promotions/${promotionId}`, manager.token);
  assert.equal(deleteRes.status, 204, JSON.stringify(deleteRes.body));
  const deleteLog = await findLatestLog(admin.token, 'promotion.delete', promotionId);
  assert.ok(deleteLog, 'ต้องมี audit log สำหรับการลบโปรโมชัน แม้โปรโมชันจะถูกลบไปแล้ว');
});

test('POST /ingredients/:id/adjust-stock — ปรับสต๊อกมือต้องถูกบันทึก audit log พร้อมเหตุผล', async () => {
  const admin = await login('admin', 'admin123');
  const ingredient = await post('/api/v1/ingredients', admin.token, {
    name: `วัตถุดิบทดสอบ audit-${Date.now()}`,
    unit: 'กรัม',
    currentStock: 100,
    lowStockThreshold: 20,
  });
  assert.equal(ingredient.status, 201, JSON.stringify(ingredient.body));
  const ingredientId = ingredient.body.data.id;

  const adjustRes = await post(`/api/v1/ingredients/${ingredientId}/adjust-stock`, admin.token, {
    delta: -30,
    note: 'ของเสียหายทดสอบ',
  });
  assert.equal(adjustRes.status, 200, JSON.stringify(adjustRes.body));

  const log = await findLatestLog(admin.token, 'ingredient.stock_adjust', ingredientId);
  assert.ok(log, 'ต้องมี audit log สำหรับการปรับสต๊อกมือ');
  assert.equal(log.entityType, 'ingredient');
  assert.equal(log.reason, 'ของเสียหายทดสอบ');
  assert.equal(log.metadata.delta, -30);
  assert.equal(log.metadata.previousStock, 100);
  assert.equal(log.metadata.newStock, 70);
});

test('GET /audit-logs/export — พนักงานเสิร์ฟ/ผู้จัดการดึงไม่ได้ สงวนไว้เฉพาะ admin', async () => {
  const waiter = await login('waiter1', 'waiter123');
  const manager = await login('manager', 'manager123');

  assert.equal((await get('/api/v1/audit-logs/export', waiter.token)).status, 403);
  assert.equal((await get('/api/v1/audit-logs/export', manager.token)).status, 403);
});

test('GET /audit-logs/export — admin ดึงเป็น CSV ได้ พร้อม header ที่ถูกต้อง', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const manager = await login('manager', 'manager123');
  const order = await openOrder(waiter.token);
  const reason = `เหตุผลทดสอบ export-${Date.now()}`;
  await post(`/api/v1/orders/${order.id}/cancel`, manager.token, { reason });

  const res = await get('/api/v1/audit-logs/export', admin.token);

  assert.equal(res.status, 200);
  assert.match(res.headers['content-type'], /text\/csv/);
  assert.match(res.headers['content-disposition'], /attachment/);
  assert.match(res.headers['content-disposition'], /audit-logs\.csv/);
  assert.match(res.text, /วันเวลา,ผู้ทำ,การกระทำ,ประเภท,รหัสอ้างอิง,รายละเอียด,เหตุผล/);
  assert.ok(res.text.includes(reason), 'CSV ต้องมีเหตุผลของ log ที่เพิ่งสร้าง');
});

test('GET /audit-logs/export — filter ตาม action ได้เหมือน list', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  await openOrder(waiter.token);

  const res = await get('/api/v1/audit-logs/export?action=order.create', admin.token);

  assert.equal(res.status, 200);
  const dataLines = res.text.trim().split('\r\n').slice(1); // ตัดบรรทัด header ออก
  assert.ok(dataLines.length > 0, 'ต้องมีอย่างน้อย 1 แถวของ order.create');
  for (const line of dataLines) {
    assert.match(line, /,order\.create,/);
  }
});

test('POST/DELETE /orders/:id/promotion — กรอก/เอาโค้ดส่วนลดออกต้องถูกบันทึก audit log ครบ', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const manager = await login('manager', 'manager123');
  const order = await openOrder(waiter.token);

  const promoRes = await post('/api/v1/promotions', manager.token, {
    name: 'ลด 15 บาท (audit test)',
    type: 'amount',
    value: 15,
    code: `AUDIT${Date.now()}`,
  });
  assert.equal(promoRes.status, 201, JSON.stringify(promoRes.body));
  const code = promoRes.body.data.code;

  const redeemRes = await post(`/api/v1/orders/${order.id}/promotion/redeem`, waiter.token, {
    code,
  });
  assert.equal(redeemRes.status, 200, JSON.stringify(redeemRes.body));

  const redeemLog = await findLatestLog(admin.token, 'order.promotion_redeem', order.id);
  assert.ok(redeemLog, 'ต้องมี audit log สำหรับการกรอกโค้ดส่วนลด');
  assert.equal(redeemLog.entityType, 'order');
  assert.match(redeemLog.summary, new RegExp(code));

  const removeRes = await del(`/api/v1/orders/${order.id}/promotion`, waiter.token);
  assert.equal(removeRes.status, 200, JSON.stringify(removeRes.body));

  const removeLog = await findLatestLog(admin.token, 'order.promotion_remove', order.id);
  assert.ok(removeLog, 'ต้องมี audit log สำหรับการเอาโปรโมชันออก');
  assert.equal(removeLog.entityType, 'order');
  assert.equal(removeLog.metadata.previousPromotionCode, code);
});

test('POST /payments — รับชำระเงินต้องถูกบันทึก audit log พร้อมยอดและช่องทาง', async () => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');
  const cashier = await login('cashier', 'cashier123');
  const order = await openOrder(waiter.token);

  const payRes = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });
  assert.equal(payRes.status, 201, JSON.stringify(payRes.body));
  const paymentId = payRes.body.data.payment.id;

  const log = await findLatestLog(admin.token, 'payment.pay', paymentId);
  assert.ok(log, 'ต้องมี audit log สำหรับการรับชำระเงิน');
  assert.equal(log.entityType, 'payment');
  assert.equal(log.metadata.orderId, order.id);
  assert.equal(log.metadata.method, 'cash');
});

test('POST /shifts และ PATCH /shifts/:id/close — เปิด/ปิดกะต้องถูกบันทึก audit log พร้อมยอดเงินสด', async () => {
  const admin = await login('admin', 'admin123');
  const manager = await login('manager', 'manager123');
  const cashier = await login('cashier', 'cashier123');

  // ปิดกะที่ seed เปิดไว้ให้ก่อน (ถ้ามี) เพื่อเปิดกะใหม่สำหรับเทสต์นี้ได้
  const current = await get('/api/v1/shifts/current', cashier.token);
  if (current.body.data) {
    await patch(`/api/v1/shifts/${current.body.data.id}/close`, manager.token, {
      countedCash: current.body.data.openingCash,
    });
  }

  const openRes = await post('/api/v1/shifts', cashier.token, { openingCash: 1500 });
  assert.equal(openRes.status, 201, JSON.stringify(openRes.body));
  const shiftId = openRes.body.data.id;

  const openLog = await findLatestLog(admin.token, 'shift.open', shiftId);
  assert.ok(openLog, 'ต้องมี audit log สำหรับการเปิดกะ');
  assert.equal(openLog.entityType, 'shift');
  assert.equal(openLog.metadata.openingCash, 150000); // สตางค์

  const closeRes = await patch(`/api/v1/shifts/${shiftId}/close`, manager.token, {
    countedCash: 1450,
    note: 'เงินขาดหาย ทดสอบ audit',
  });
  assert.equal(closeRes.status, 200, JSON.stringify(closeRes.body));

  const closeLog = await findLatestLog(admin.token, 'shift.close', shiftId);
  assert.ok(closeLog, 'ต้องมี audit log สำหรับการปิดกะ');
  assert.equal(closeLog.reason, 'เงินขาดหาย ทดสอบ audit');
  assert.equal(closeLog.metadata.variance, -5000); // 1450 - 1500 บาท = -50 บาท = -5000 สตางค์
});
