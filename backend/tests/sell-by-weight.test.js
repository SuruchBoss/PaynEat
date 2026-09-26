// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after, before } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

// ขายตามน้ำหนัก (ดู docs/tickets/18-sell-by-weight.md, docs/DECISIONS.md #48/#51)

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

let admin;
let cashier;
let categoryId;
let porkBelly;
let porkStockId;

const uniq = () => `${Date.now()}-${Math.round(Math.random() * 1e6)}`;

const createWeightItem = async ({ price, stock, extra = {} } = {}) => {
  const ingredient = await post('/api/v1/ingredients', admin.token, {
    name: `หมูทดสอบ-${uniq()}`,
    unit: 'กก.',
    currentStock: stock ?? 10,
    lowStockThreshold: 0,
  });
  const menu = await post('/api/v1/menu-items', admin.token, {
    categoryId,
    name: `หมูชั่งกิโล-${uniq()}`,
    price: price ?? 280,
    soldByWeight: true,
    ingredients: [{ ingredientId: ingredient.body.data.id, qtyPerUnit: 1 }],
    ...extra,
  });
  assert.equal(menu.status, 201, JSON.stringify(menu.body));
  return { menu: menu.body.data, ingredientId: ingredient.body.data.id };
};

const stockOf = async (ingredientId) =>
  (await get(`/api/v1/ingredients/${ingredientId}`, admin.token)).body.data.currentStock;

const takeaway = (items) => post('/api/v1/orders', cashier.token, { type: 'takeaway', items });

before(async () => {
  admin = await login('admin', 'admin123');
  cashier = await login('cashier', 'cashier123');
  const category = await post('/api/v1/categories', admin.token, { name: `เนื้อชั่ง-${uniq()}` });
  categoryId = category.body.data.id;
  ({ menu: porkBelly, ingredientId: porkStockId } = await createWeightItem({ stock: 25 }));
});

test('เมนูขายตามน้ำหนัก: soldByWeight ติดมากับ DTO ทั้งตอนสร้างและตอนดึง', async () => {
  assert.equal(porkBelly.soldByWeight, true);
  const res = await get(`/api/v1/menu-items/${porkBelly.id}`, admin.token);
  assert.equal(res.body.data.soldByWeight, true);

  const seeded = await get('/api/v1/menu-items?limit=200&search=หมูสามชั้นสไลซ์', admin.token);
  assert.equal(seeded.body.data[0].soldByWeight, true, 'seed มีเมนูขายตามน้ำหนักให้ลองทันที');
});

test('ราคาบรรทัด = ราคาต่อกก. × กรัม / 1000 ปัดเป็นสตางค์ และยอดบิลคิดจากยอดนั้น', async () => {
  const res = await takeaway([{ menuItemId: porkBelly.id, quantity: 1, weightGrams: 485 }]);
  assert.equal(res.status, 201, JSON.stringify(res.body));
  const [line] = res.body.data.items;
  assert.equal(line.weightGrams, 485);
  assert.equal(line.quantity, 1);
  assert.equal(line.lineTotal, 135.8); // 280 × 0.485
  assert.equal(res.body.data.subtotal, 135.8);
});

test('ปัดเศษสตางค์แบบเดียวกับที่แอปคิด: 123.45 บาท/กก. × 333 กรัม = 41.11 บาท', async () => {
  const { menu } = await createWeightItem({ price: 123.45 });
  const res = await takeaway([{ menuItemId: menu.id, quantity: 1, weightGrams: 333 }]);
  // 12345 สตางค์ × 333 / 1000 = 4110.885 → 4111 สตางค์
  assert.equal(res.body.data.items[0].lineTotal, 41.11);
});

test('ตัวเลือกของสินค้าชั่งน้ำหนักบวกเป็นราคาต่อกก. (หมักซอส +40/กก.)', async () => {
  const { menu } = await createWeightItem({
    extra: {
      optionGroups: [
        {
          name: 'การเตรียม',
          maxSelect: 1,
          options: [{ name: 'หมักซอส', priceDelta: 40 }],
        },
      ],
    },
  });
  const optionId = menu.optionGroups[0].options[0].id;
  const res = await takeaway([
    { menuItemId: menu.id, quantity: 1, weightGrams: 485, optionIds: [optionId] },
  ]);
  assert.equal(res.body.data.items[0].lineTotal, 155.2); // (280 + 40) × 0.485
});

test('กติกาการสั่ง: ต้องมีน้ำหนัก, สินค้าชิ้นห้ามมีน้ำหนัก, สินค้าชั่งบรรทัดละ 1 ถุง', async () => {
  const noWeight = await takeaway([{ menuItemId: porkBelly.id, quantity: 1 }]);
  assert.equal(noWeight.status, 400);
  assert.match(noWeight.body.error.message, /ขายตามน้ำหนัก/);

  const menu = await get('/api/v1/menu-items?limit=200', admin.token);
  const unitItem = menu.body.data.find((item) => !item.soldByWeight && item.isAvailable);
  const unitWithWeight = await takeaway([
    { menuItemId: unitItem.id, quantity: 1, weightGrams: 200 },
  ]);
  assert.equal(unitWithWeight.status, 400);

  const twoBags = await takeaway([{ menuItemId: porkBelly.id, quantity: 2, weightGrams: 500 }]);
  assert.equal(twoBags.status, 400);
  assert.match(twoBags.body.error.message, /บรรทัดละ 1 ถุง/);

  const tooHeavy = await takeaway([{ menuItemId: porkBelly.id, quantity: 1, weightGrams: 100000 }]);
  assert.equal(tooHeavy.status, 422);
});

test('สต๊อกลดตามกิโลที่ขายจริงตอนส่งครัว และคืนครบเมื่อลบรายการ', async () => {
  const before = await stockOf(porkStockId);
  const created = await takeaway([{ menuItemId: porkBelly.id, quantity: 1, weightGrams: 485 }]);
  const orderId = created.body.data.id;
  const itemId = created.body.data.items[0].id;

  assert.equal(await stockOf(porkStockId), before, 'ร่างยังไม่ตัดสต๊อก');
  await post(`/api/v1/orders/${orderId}/send-to-kitchen`, cashier.token);
  assert.equal(
    Number((await stockOf(porkStockId)).toFixed(6)),
    Number((before - 0.485).toFixed(6)),
  );

  // แก้จำนวนของบรรทัดชั่งน้ำหนักไม่ได้ ต้องลบแล้วชั่งใหม่
  const edit = await patch(`/api/v1/orders/${orderId}/items/${itemId}`, cashier.token, {
    quantity: 2,
  });
  assert.equal(edit.status, 400);

  const removed = await del(`/api/v1/orders/${orderId}/items/${itemId}`, cashier.token);
  assert.equal(removed.status, 200);
  assert.equal(Number((await stockOf(porkStockId)).toFixed(6)), Number(before.toFixed(6)));
});

test('เมนูชั่งน้ำหนักยังขายได้ตอนสต๊อกเหลือไม่ถึง 1 กก. และปิดขายเองเมื่อหมดจริง', async () => {
  const { menu, ingredientId } = await createWeightItem({ stock: 0.8 });
  const first = await takeaway([{ menuItemId: menu.id, quantity: 1, weightGrams: 300 }]);
  await post(`/api/v1/orders/${first.body.data.id}/send-to-kitchen`, cashier.token);

  const afterFirst = await get(`/api/v1/menu-items/${menu.id}`, admin.token);
  assert.equal(afterFirst.body.data.isAvailable, true, 'เหลือ 0.5 กก. ยังต้องขายได้');

  const second = await takeaway([{ menuItemId: menu.id, quantity: 1, weightGrams: 500 }]);
  await post(`/api/v1/orders/${second.body.data.id}/send-to-kitchen`, cashier.token);
  assert.ok(Math.abs(await stockOf(ingredientId)) < 1e-9);

  const afterSecond = await get(`/api/v1/menu-items/${menu.id}`, admin.token);
  assert.equal(afterSecond.body.data.isAvailable, false, 'หมดแล้วต้องขึ้นหมดเอง');
});

test('จ่ายเงินบิลที่ไม่เคยส่งครัว (เคาน์เตอร์ชั่งแล้วจ่ายเลย) ต้องตัดสต๊อกด้วย (#51)', async () => {
  const before = await stockOf(porkStockId);
  const created = await takeaway([{ menuItemId: porkBelly.id, quantity: 1, weightGrams: 1250 }]);
  const order = created.body.data;
  assert.equal(order.status, 'open');

  const pay = await post('/api/v1/payments', cashier.token, {
    orderId: order.id,
    method: 'cash',
    amount: order.total,
    received: order.total,
  });
  assert.equal(pay.status, 201, JSON.stringify(pay.body));
  assert.equal(pay.body.data.order.status, 'paid');
  assert.equal(Number((await stockOf(porkStockId)).toFixed(6)), Number((before - 1.25).toFixed(6)));

  // บิลที่ส่งครัวไปแล้วต้องไม่ถูกตัดซ้ำตอนจ่าย
  const sent = await takeaway([{ menuItemId: porkBelly.id, quantity: 1, weightGrams: 200 }]);
  await post(`/api/v1/orders/${sent.body.data.id}/send-to-kitchen`, cashier.token);
  const afterSend = await stockOf(porkStockId);
  const sentOrder = (await get(`/api/v1/orders/${sent.body.data.id}`, cashier.token)).body.data;
  await post('/api/v1/payments', cashier.token, {
    orderId: sentOrder.id,
    method: 'transfer',
    amount: sentOrder.total,
  });
  assert.equal(await stockOf(porkStockId), afterSend);
});

test('รายงานเมนูขายดีบอกน้ำหนักรวมที่ขายได้ และ audit log เขียนเป็นกิโลกรัม', async () => {
  const today = new Date().toISOString().slice(0, 10);
  const top = await get(
    `/api/v1/reports/top-items?from=${today}&to=${today}&limit=50`,
    admin.token,
  );
  const row = top.body.data.find((item) => item.name === porkBelly.name);
  assert.ok(row, 'หมูที่ขายไปต้องอยู่ในรายงาน');
  // นับเฉพาะบิลที่จ่ายแล้ว: 1,250 + 200 กรัมจากเทสต์ก่อนหน้า (บิลที่ยังไม่จ่ายไม่นับ)
  assert.equal(row.weightKg, 1.45);

  const csv = await get(
    `/api/v1/reports/export/top-items?from=${today}&to=${today}&limit=50`,
    admin.token,
  );
  assert.match(csv.text, /น้ำหนักรวม \(กก\.\)/);

  const logs = await get('/api/v1/audit-logs?action=order.create&limit=50', admin.token);
  assert.equal(logs.status, 200);
  const created = await takeaway([{ menuItemId: porkBelly.id, quantity: 1, weightGrams: 485 }]);
  const add = await post(`/api/v1/orders/${created.body.data.id}/items`, cashier.token, {
    items: [{ menuItemId: porkBelly.id, quantity: 1, weightGrams: 250 }],
  });
  assert.equal(add.status, 201);
  const addLogs = await get('/api/v1/audit-logs?action=order.item.add&limit=5', admin.token);
  assert.ok(
    addLogs.body.data.some((log) => log.summary.includes('0.250 กก.')),
    'audit log ต้องบอกน้ำหนัก ไม่ใช่ x1',
  );
});

test('QR สั่งเอง: เมนูชั่งน้ำหนักไม่โผล่ในเมนูลูกค้า และยิง API ตรงก็ถูกปฏิเสธ', async () => {
  const tables = await get('/api/v1/tables', admin.token);
  const table = tables.body.data.find((row) => row.status === 'available');
  const menu = await api().get(`/api/v1/public/tables/${table.qrToken}/menu`);
  assert.equal(menu.status, 200);
  assert.ok(menu.body.data.items.every((item) => item.soldByWeight !== true));
  assert.ok(menu.body.data.items.every((item) => item.barcode === undefined));
  // แต่บอกจำนวนที่ซ่อนไว้ หน้า QR จะได้บอกลูกค้าให้สั่งกับพนักงาน (DECISIONS #64)
  const all = await get('/api/v1/menu-items?availableOnly=true&limit=200', admin.token);
  const weighed = all.body.data.filter((item) => item.soldByWeight).length;
  assert.ok(weighed > 0);
  assert.equal(menu.body.data.staffOnlyCount, weighed);

  const res = await api()
    .post(`/api/v1/public/tables/${table.qrToken}/items`)
    .send({ items: [{ menuItemId: porkBelly.id, quantity: 1 }] });
  assert.equal(res.status, 409);
  assert.match(res.body.error.message, /เรียกพนักงาน/);
});
