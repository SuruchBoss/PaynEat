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

test('สต๊อกวัตถุดิบ: ตัดตอนส่งครัว/เพิ่มรายการ → auto unavailable → คืนสต๊อกตอนยกเลิก/ลบ', async (t) => {
  const admin = await login('admin', 'admin123');
  const waiter = await login('waiter1', 'waiter123');

  let ingredient;
  let menuItem;
  let table;
  let orderId;

  await t.test(
    '0) เตรียมวัตถุดิบ + เมนูที่ผูกวัตถุดิบไว้ (สต๊อกตั้งต้น 3 ชิ้น ใช้ 1 ชิ้นต่อที่)',
    async () => {
      const ingredientRes = await post('/api/v1/ingredients', admin.token, {
        name: `กุ้งทดสอบ-${Date.now()}`,
        unit: 'ชิ้น',
        currentStock: 3,
        lowStockThreshold: 1,
      });
      assert.equal(ingredientRes.status, 201);
      ingredient = ingredientRes.body.data;

      const categoryRes = await post('/api/v1/categories', admin.token, {
        name: `หมวดทดสอบสต๊อก-${Date.now()}`,
      });
      const menuRes = await post('/api/v1/menu-items', admin.token, {
        categoryId: categoryRes.body.data.id,
        name: `เมนูทดสอบสต๊อก-${Date.now()}`,
        price: 100,
        ingredients: [{ ingredientId: ingredient.id, qtyPerUnit: 1 }],
      });
      assert.equal(menuRes.status, 201);
      menuItem = menuRes.body.data;
      assert.equal(menuItem.isAvailable, true);

      const tablesRes = await get('/api/v1/tables', waiter.token);
      table = tablesRes.body.data.find((row) => row.status === 'available');
      assert.ok(table, 'ต้องมีโต๊ะว่างอย่างน้อย 1 โต๊ะ');
    },
  );

  await t.test('1) เปิดออเดอร์ 2 ที่ แล้วยังไม่ตัดสต๊อกจนกว่าจะส่งครัว', async () => {
    const orderRes = await post('/api/v1/orders', waiter.token, {
      type: 'dine_in',
      tableId: table.id,
      guestCount: 2,
      items: [{ menuItemId: menuItem.id, quantity: 2 }],
    });
    assert.equal(orderRes.status, 201);
    orderId = orderRes.body.data.id;

    const stillFull = await get(`/api/v1/ingredients/${ingredient.id}`, admin.token);
    assert.equal(stillFull.body.data.currentStock, 3);
  });

  await t.test('2) ส่งครัว → ตัดสต๊อกตามจำนวน (2 ที่ × 1 ชิ้น = 2 ชิ้น เหลือ 1)', async () => {
    const res = await post(`/api/v1/orders/${orderId}/send-to-kitchen`, waiter.token);
    assert.equal(res.status, 200);

    const afterSend = await get(`/api/v1/ingredients/${ingredient.id}`, admin.token);
    assert.equal(afterSend.body.data.currentStock, 1);

    const menuAfterSend = await get(`/api/v1/menu-items/${menuItem.id}`, waiter.token);
    assert.equal(menuAfterSend.body.data.isAvailable, true); // เหลือ 1 >= qtyPerUnit(1) ยังสั่งได้
  });

  await t.test('3) ส่งครัวซ้ำ (เช่นกดซ้ำ) ต้องไม่ตัดสต๊อกซ้ำรายการเดิม', async () => {
    const res = await post(`/api/v1/orders/${orderId}/send-to-kitchen`, waiter.token);
    assert.equal(res.status, 200);

    const stillOne = await get(`/api/v1/ingredients/${ingredient.id}`, admin.token);
    assert.equal(stillOne.body.data.currentStock, 1);
  });

  let addedItemId;

  await t.test(
    '4) เพิ่มรายการเข้าออเดอร์ที่ส่งครัวไปแล้ว → ตัดสต๊อกทันที (ไม่ต้องกดส่งครัวซ้ำ) จนหมด (0 ชิ้น) → เมนูถูกปิดขายอัตโนมัติ',
    async () => {
      const res = await post(`/api/v1/orders/${orderId}/items`, waiter.token, {
        items: [{ menuItemId: menuItem.id, quantity: 1 }],
      });
      assert.equal(res.status, 201);
      addedItemId = res.body.data.items.find(
        (item) => item.menuItemId === menuItem.id && item.quantity === 1,
      ).id;

      const afterAdd = await get(`/api/v1/ingredients/${ingredient.id}`, admin.token);
      assert.equal(afterAdd.body.data.currentStock, 0);

      const menuAfterAdd = await get(`/api/v1/menu-items/${menuItem.id}`, waiter.token);
      assert.equal(menuAfterAdd.body.data.isAvailable, false);
    },
  );

  await t.test('5) เมนูที่ถูกปิดขายอัตโนมัติ สั่งเป็นออเดอร์ใหม่ไม่ได้ (409)', async () => {
    const res = await post('/api/v1/orders', waiter.token, {
      type: 'takeaway',
      guestCount: 1,
      items: [{ menuItemId: menuItem.id, quantity: 1 }],
    });
    assert.equal(res.status, 409);
  });

  await t.test(
    '6) ยกเลิกรายการที่เพิ่งเพิ่ม (ยังไม่เริ่มทำ) → คืนสต๊อก 1 ชิ้น → เมนูกลับมาเปิดขายอัตโนมัติ',
    async () => {
      const res = await patch(
        `/api/v1/orders/${orderId}/items/${addedItemId}/status`,
        waiter.token,
        { status: 'cancelled' },
      );
      assert.equal(res.status, 200);

      const afterCancel = await get(`/api/v1/ingredients/${ingredient.id}`, admin.token);
      assert.equal(afterCancel.body.data.currentStock, 1);

      const menuAfterCancel = await get(`/api/v1/menu-items/${menuItem.id}`, waiter.token);
      assert.equal(menuAfterCancel.body.data.isAvailable, true);
    },
  );

  await t.test(
    '7) ปรับสต๊อกมือให้หมด (adjust-stock) → เมนูถูกปิดขายอัตโนมัติเช่นกัน (ไม่ใช่แค่ทาง order)',
    async () => {
      const res = await post(`/api/v1/ingredients/${ingredient.id}/adjust-stock`, admin.token, {
        delta: -1,
      });
      assert.equal(res.status, 200);
      assert.equal(res.body.data.currentStock, 0);

      const menuRes = await get(`/api/v1/menu-items/${menuItem.id}`, waiter.token);
      assert.equal(menuRes.body.data.isAvailable, false);
    },
  );

  await t.test('8) เติมสต๊อกกลับมาเพียงพอ → เมนูเปิดขายอัตโนมัติกลับมาเอง', async () => {
    const res = await post(`/api/v1/ingredients/${ingredient.id}/adjust-stock`, admin.token, {
      delta: 5,
    });
    assert.equal(res.status, 200);
    assert.equal(res.body.data.currentStock, 5);

    const menuRes = await get(`/api/v1/menu-items/${menuItem.id}`, waiter.token);
    assert.equal(menuRes.body.data.isAvailable, true);
  });

  let pendingItemId;

  await t.test(
    '9) เพิ่มรายการใหม่ (สต๊อกพอ) แล้วแก้จำนวนก่อนส่งครัว → ยังไม่ตัดสต๊อก',
    async () => {
      const res = await post(`/api/v1/orders/${orderId}/items`, waiter.token, {
        items: [{ menuItemId: menuItem.id, quantity: 1 }],
      });
      assert.equal(res.status, 201);
      // รายการนี้ถูกเพิ่มตอนออเดอร์ส่งครัวไปแล้ว (in_kitchen) จึงตัดสต๊อกทันทีเหมือนขั้นตอน 4
      const stockAfterAdd = await get(`/api/v1/ingredients/${ingredient.id}`, admin.token);
      assert.equal(stockAfterAdd.body.data.currentStock, 4);
      // ใช้ status === 'pending' ช่วยแยกจากรายการเดิมที่ถูกยกเลิกไปแล้วในขั้นตอน 6
      // (menuItemId/quantity เดียวกันแต่ status ต่างกัน)
      pendingItemId = res.body.data.items.find(
        (item) =>
          item.menuItemId === menuItem.id && item.quantity === 1 && item.status === 'pending',
      ).id;
    },
  );

  await t.test(
    '10) แก้จำนวนรายการที่ตัดสต๊อกไปแล้ว (1 → 3) → ตัดสต๊อกเพิ่มตามส่วนต่าง (2 ชิ้น)',
    async () => {
      const res = await patch(`/api/v1/orders/${orderId}/items/${pendingItemId}`, waiter.token, {
        quantity: 3,
      });
      assert.equal(res.status, 200);

      const stockAfterQtyChange = await get(`/api/v1/ingredients/${ingredient.id}`, admin.token);
      assert.equal(stockAfterQtyChange.body.data.currentStock, 2); // 4 - (3-1)
    },
  );

  await t.test(
    '11) ลบรายการที่ตัดสต๊อกไปแล้ว (removeItem ตอนยังเป็น pending) → คืนสต๊อกเต็มจำนวน',
    async () => {
      const res = await del(`/api/v1/orders/${orderId}/items/${pendingItemId}`, waiter.token);
      assert.equal(res.status, 200);

      const stockAfterRemove = await get(`/api/v1/ingredients/${ingredient.id}`, admin.token);
      assert.equal(stockAfterRemove.body.data.currentStock, 5); // คืนกลับ 3 ชิ้น (2+3)
    },
  );

  await t.test('12) ยกเลิกทั้งออเดอร์ → คืนสต๊อกของทุกรายการที่ยังตัดค้างอยู่', async () => {
    const beforeCancel = await get(`/api/v1/ingredients/${ingredient.id}`, admin.token);
    const stockBefore = beforeCancel.body.data.currentStock;

    const res = await post(`/api/v1/orders/${orderId}/cancel`, admin.token, {
      reason: 'ทดสอบยกเลิกทั้งออเดอร์',
    });
    assert.equal(res.status, 200);

    // ออเดอร์นี้เหลือรายการเดิม 2 ที่ (ตัดสต๊อกไปตั้งแต่ขั้นตอน 2) ที่ยังไม่ได้เสิร์ฟ → ต้องคืนกลับ
    const afterCancel = await get(`/api/v1/ingredients/${ingredient.id}`, admin.token);
    assert.equal(afterCancel.body.data.currentStock, stockBefore + 2);
  });
});
