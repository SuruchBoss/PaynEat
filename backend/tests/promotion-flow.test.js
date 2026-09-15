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
const patch = (url, token, body) =>
  api()
    .patch(url)
    .set(authHeader(token))
    .send(body ?? {});
const del = (url, token) => api().delete(url).set(authHeader(token));

// โปรโมชันถูกประเมินใหม่ตอน recalculate() เท่านั้น (ตอนแก้ไขออเดอร์) ไม่ใช่ตอน GET เฉย ๆ
// เหมือนกับ VAT/Service Charge ที่ใช้ค่าที่คำนวณไว้ล่าสุดจนกว่าจะมีการแก้ไขออเดอร์อีกครั้ง
// เทสต์นี้เลยต้อง "แตะ" ออเดอร์เบา ๆ (ส่งส่วนลด none) เพื่อบังคับให้คำนวณใหม่ก่อนเช็คผล
const touch = (orderId, token) =>
  post(`/api/v1/orders/${orderId}/discount`, token, {
    type: 'none',
    value: 0,
  });

test('โปรโมชัน: สร้าง → auto apply → กรอกโค้ด → ลบ → สิทธิ์การเข้าถึง', async (t) => {
  const manager = await login('manager', 'manager123');
  const waiter = await login('waiter1', 'waiter123');

  let table;
  let menuItem;
  let orderId;
  let autoPromotionId;
  let codePromotionId;

  await t.test('0) เตรียมโต๊ะ/เมนู/ออเดอร์สำหรับทดสอบ', async () => {
    const tablesRes = await get('/api/v1/tables', waiter.token);
    table = tablesRes.body.data.find((row) => row.status === 'available');
    assert.ok(table, 'ต้องมีโต๊ะว่างอย่างน้อย 1 โต๊ะ');

    const menuRes = await get('/api/v1/menu-items?availableOnly=true&limit=200', waiter.token);
    // ใช้เมนูที่ไม่มีกลุ่มตัวเลือกบังคับ (ดู OPTION_MAP ใน db/seed.js) จะได้สร้างออเดอร์ได้โดยไม่ต้องเลือก option
    menuItem = menuRes.body.data.find((item) => item.name === 'ข้าวหมูกรอบ');
    assert.ok(menuItem, 'ข้อมูลตัวอย่างต้องมีเมนูข้าวหมูกรอบ');

    const orderRes = await post('/api/v1/orders', waiter.token, {
      type: 'dine_in',
      tableId: table.id,
      guestCount: 2,
      items: [{ menuItemId: menuItem.id, quantity: 2 }],
    });
    assert.equal(orderRes.status, 201);
    orderId = orderRes.body.data.id;
    assert.equal(orderRes.body.data.subtotal, menuItem.price * 2);
    assert.equal(orderRes.body.data.promotionDiscountAmount, 0);
  });

  await t.test('1) พนักงานเสิร์ฟสร้างโปรโมชันไม่ได้ (RBAC 403)', async () => {
    const res = await post('/api/v1/promotions', waiter.token, {
      name: 'ลอง 403',
      type: 'percent',
      value: 10,
    });
    assert.equal(res.status, 403);
  });

  await t.test('2) ผู้จัดการสร้างโปรโมชันแบบ auto (ไม่ใช้โค้ด) ได้', async () => {
    const res = await post('/api/v1/promotions', manager.token, {
      name: 'ลด 10% ทั้งบิล',
      type: 'percent',
      value: 10,
      conditions: {},
    });
    assert.equal(res.status, 201);
    assert.equal(res.body.data.code, null);
    assert.equal(res.body.data.value, 10);
    autoPromotionId = res.body.data.id;
  });

  await t.test('3) ออเดอร์เดิมถูก apply โปรโมชัน auto ให้ตอนคำนวณใหม่ครั้งถัดไป', async () => {
    const res = await touch(orderId, manager.token);
    assert.equal(res.status, 200);
    assert.equal(res.body.data.promotionId, autoPromotionId);
    assert.equal(res.body.data.promotionName, 'ลด 10% ทั้งบิล');
    const expectedDiscount = Number((menuItem.price * 2 * 0.1).toFixed(2));
    assert.equal(res.body.data.promotionDiscountAmount, expectedDiscount);
  });

  await t.test('4) ลบโปรโมชัน auto ออก แต่เข้าเงื่อนไขอยู่ ระบบจะใส่กลับให้ทันที', async () => {
    const res = await del(`/api/v1/orders/${orderId}/promotion`, waiter.token);
    assert.equal(res.status, 200);
    assert.equal(res.body.data.promotionId, autoPromotionId); // auto กลับมาเองเพราะยังเข้าเงื่อนไข
  });

  await t.test('5) ปิดใช้งานโปรโมชัน auto แล้วออเดอร์ต้องไม่มีโปรโมชันอีกต่อไป', async () => {
    const offRes = await patch(`/api/v1/promotions/${autoPromotionId}`, manager.token, {
      isActive: false,
    });
    assert.equal(offRes.status, 200);
    assert.equal(offRes.body.data.isActive, false);

    const orderRes = await touch(orderId, manager.token);
    assert.equal(orderRes.body.data.promotionId, null);
    assert.equal(orderRes.body.data.promotionDiscountAmount, 0);
  });

  await t.test('6) สร้างโปรโมชันแบบใช้โค้ดได้ และโค้ดซ้ำต้องได้ 409', async () => {
    const res = await post('/api/v1/promotions', manager.token, {
      name: 'ลด 20 บาท',
      type: 'amount',
      value: 20,
      code: 'save20',
    });
    assert.equal(res.status, 201);
    assert.equal(res.body.data.code, 'SAVE20'); // โค้ดถูก normalize เป็นตัวใหญ่
    codePromotionId = res.body.data.id;

    const dup = await post('/api/v1/promotions', manager.token, {
      name: 'ลด 20 บาท (ซ้ำ)',
      type: 'amount',
      value: 20,
      code: 'SAVE20',
    });
    assert.equal(dup.status, 409);
  });

  await t.test('7) กรอกโค้ดผิด/ไม่มีอยู่จริง → 404', async () => {
    const res = await post(`/api/v1/orders/${orderId}/promotion/redeem`, waiter.token, {
      code: 'NOTREAL',
    });
    assert.equal(res.status, 404);
  });

  await t.test('8) กรอกโค้ดที่ถูกต้อง → apply ทันที', async () => {
    const res = await post(`/api/v1/orders/${orderId}/promotion/redeem`, waiter.token, {
      code: 'save20',
    });
    assert.equal(res.status, 200);
    assert.equal(res.body.data.promotionId, codePromotionId);
    assert.equal(res.body.data.promotionCode, 'SAVE20');
    assert.equal(res.body.data.promotionDiscountAmount, 20);
  });

  await t.test(
    '9) เปิดโปรโมชัน auto กลับมา — โค้ดที่กรอกไว้ต้องไม่ถูกแทนที่อัตโนมัติ',
    async () => {
      await patch(`/api/v1/promotions/${autoPromotionId}`, manager.token, { isActive: true });
      const res = await touch(orderId, manager.token);
      // โค้ดให้ส่วนลดแค่ 20 บาท ส่วน auto (10%) ให้มากกว่า แต่ต้องยึดโค้ดที่กรอกไว้เป็นหลัก
      assert.equal(res.body.data.promotionId, codePromotionId);
      assert.equal(res.body.data.promotionCode, 'SAVE20');
    },
  );

  await t.test('10) ลบโปรโมชัน (โค้ด) ออก → กลับไปใช้ auto ที่ยังเข้าเงื่อนไขแทน', async () => {
    const res = await del(`/api/v1/orders/${orderId}/promotion`, waiter.token);
    assert.equal(res.status, 200);
    assert.equal(res.body.data.promotionId, autoPromotionId);
    assert.equal(res.body.data.promotionCode, null);
  });

  await t.test('11) GET eligible-promotions คืนรายการที่เข้าเงื่อนไขตอนนี้', async () => {
    const res = await get(`/api/v1/orders/${orderId}/eligible-promotions`, waiter.token);
    assert.equal(res.status, 200);
    const auto = res.body.data.find((entry) => entry.promotionId === autoPromotionId);
    assert.ok(auto);
    assert.equal(auto.isEligibleNow, true);
    assert.equal(auto.isCurrentlyApplied, true);
    assert.equal(auto.requiresCode, false);
  });

  await t.test('12) ผู้จัดการลบโปรโมชันได้ พนักงานเสิร์ฟลบไม่ได้ (RBAC 403)', async () => {
    const forbidden = await del(`/api/v1/promotions/${codePromotionId}`, waiter.token);
    assert.equal(forbidden.status, 403);

    const ok = await del(`/api/v1/promotions/${codePromotionId}`, manager.token);
    assert.equal(ok.status, 204);

    // ลบโปรโมชันที่เคยใช้ในออเดอร์แล้วไม่กระทบออเดอร์เก่า เพราะ snapshot ชื่อ/โค้ดไว้แล้ว
    const orderRes = await get(`/api/v1/orders/${orderId}`, waiter.token);
    assert.equal(orderRes.status, 200);
  });
});
