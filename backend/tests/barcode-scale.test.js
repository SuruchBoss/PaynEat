// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after, before } from 'node:test';
import assert from 'node:assert/strict';
import { api, login, authHeader, cleanup } from './helpers/testApp.js';

// บาร์โค้ดสินค้า + รหัสสินค้าบนฉลากตาชั่ง (ดู docs/tickets/19-barcode-scale.md, docs/DECISIONS.md #49)
// การแยกฉลากตาชั่งเกิดฝั่งแอป (scale_barcode.dart) — ฝั่ง backend มีหน้าที่เก็บรหัสให้ถูกรูป ไม่ซ้ำ
// และเก็บรูปแบบฉลากของร้านไว้ในการตั้งค่า

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
let categoryId;
const uniq = () => `${Date.now()}-${Math.round(Math.random() * 1e6)}`;

const createItem = (body) =>
  post('/api/v1/menu-items', admin.token, {
    categoryId,
    name: `สินค้าบาร์โค้ด-${uniq()}`,
    price: 99,
    ...body,
  });

before(async () => {
  admin = await login('admin', 'admin123');
  const category = await post('/api/v1/categories', admin.token, { name: `บาร์โค้ด-${uniq()}` });
  categoryId = category.body.data.id;
});

test('seed มีสินค้าบาร์โค้ด EAN-13 จริงและเมนูชั่งน้ำหนักพร้อม PLU ให้ลองสแกนได้ทันที', async () => {
  const res = await get('/api/v1/menu-items?limit=200', admin.token);
  const sauce = res.body.data.find((item) => item.barcode === '8850999320014');
  assert.ok(sauce, 'ต้องมีซอสหมักบุลโกกิที่มีบาร์โค้ด');
  assert.equal(sauce.soldByWeight, false);

  const pork = res.body.data.find((item) => item.scalePlu === '101');
  assert.ok(pork, 'ต้องมีเมนูชั่งน้ำหนักที่ผูก PLU 101');
  assert.equal(pork.soldByWeight, true);
});

test('บาร์โค้ดซ้ำในสาขาเดียวกันไม่ได้ (สแกนแล้วต้องได้สินค้าเดียว) แต่ต่างสาขาใช้ซ้ำได้', async () => {
  const code = `8850${String(Date.now()).slice(-9)}`;
  const first = await createItem({ barcode: code });
  assert.equal(first.status, 201, JSON.stringify(first.body));
  assert.equal(first.body.data.barcode, code);

  const dup = await createItem({ barcode: code });
  assert.equal(dup.status, 409);
  assert.match(dup.body.error.message, /ถูกใช้กับเมนู/);

  // admin โหมดทุกสาขาสร้างเมนูให้สาขาทองหล่อด้วยบาร์โค้ดเดียวกันได้ (คนละร้าน คนละชั้นวาง)
  const branches = await get('/api/v1/branches', admin.token);
  const thonglor = branches.body.data.find((branch) => branch.code === 'THONGLOR');
  const all = await post('/api/v1/auth/select-branch', admin.token, { branchId: null });
  const otherBranch = await post('/api/v1/menu-items', all.body.data.token, {
    categoryId,
    name: `สินค้าสาขาอื่น-${uniq()}`,
    price: 99,
    barcode: code,
    branchId: thonglor.id,
  });
  assert.equal(otherBranch.status, 201, JSON.stringify(otherBranch.body));
});

test('แก้เมนูตัวเองโดยส่งบาร์โค้ดเดิมกลับมาไม่ถือว่าซ้ำ และส่ง "" เพื่อล้างบาร์โค้ดได้', async () => {
  const code = `8851${String(Date.now()).slice(-9)}`;
  const created = await createItem({ barcode: code });
  const id = created.body.data.id;

  const same = await patch(`/api/v1/menu-items/${id}`, admin.token, { barcode: code, price: 109 });
  assert.equal(same.status, 200, JSON.stringify(same.body));

  const cleared = await patch(`/api/v1/menu-items/${id}`, admin.token, { barcode: '' });
  assert.equal(cleared.body.data.barcode, null);
});

test('PLU เก็บแบบตัดเลข 0 นำหน้า ใช้ได้เฉพาะเมนูขายตามน้ำหนัก และล้างเองเมื่อเลิกขายตามน้ำหนัก', async () => {
  const plu = String(900 + (Date.now() % 90));
  const weight = await createItem({ soldByWeight: true, scalePlu: `00${plu}` });
  assert.equal(weight.status, 201, JSON.stringify(weight.body));
  assert.equal(weight.body.data.scalePlu, plu, 'ฉลากพิมพ์ "00xxx" แต่ฟอร์มพิมพ์ "xxx" ต้องเท่ากัน');

  const dup = await createItem({ soldByWeight: true, scalePlu: plu });
  assert.equal(dup.status, 409);

  const unitWithPlu = await createItem({ scalePlu: '777' });
  assert.equal(unitWithPlu.status, 400);
  assert.match(unitWithPlu.body.error.message, /ขายตามน้ำหนัก/);

  const switched = await patch(`/api/v1/menu-items/${weight.body.data.id}`, admin.token, {
    soldByWeight: false,
  });
  assert.equal(switched.body.data.soldByWeight, false);
  assert.equal(switched.body.data.scalePlu, null, 'ฉลากเก่าต้องไม่ชี้มาที่เมนูขายเป็นชิ้น');

  const badFormat = await createItem({ soldByWeight: true, scalePlu: '12AB' });
  assert.equal(badFormat.status, 422);
});

test('ค้นหาเมนูด้วยบาร์โค้ดต้องตรงทั้งรหัส ไม่ใช่ขึ้นต้นเหมือนกัน', async () => {
  const exact = await get('/api/v1/menu-items?search=8850999320014', admin.token);
  assert.equal(exact.body.data.length, 1);
  assert.equal(exact.body.data[0].barcode, '8850999320014');

  const prefix = await get('/api/v1/menu-items?search=8850999', admin.token);
  assert.equal(prefix.body.data.length, 0);
});

test('ตั้งรูปแบบฉลากตาชั่งได้ และตรวจว่าเหลือหลักน้ำหนักพอ', async () => {
  const defaults = await get('/api/v1/settings', admin.token);
  assert.equal(defaults.body.data.scaleLabelPrefix, '20');
  assert.equal(defaults.body.data.scaleLabelPluDigits, 5);

  const updated = await patch('/api/v1/settings', admin.token, {
    scaleLabelPrefix: '2',
    scaleLabelPluDigits: 6,
  });
  assert.equal(updated.status, 200);
  assert.equal(updated.body.data.scaleLabelPrefix, '2');
  assert.equal(updated.body.data.scaleLabelPluDigits, 6);

  // 12 − 3 − 6 = เหลือหลักน้ำหนัก 3 หลัก ไม่พอบอกน้ำหนักเกิน 999 กรัม
  const tooLong = await patch('/api/v1/settings', admin.token, {
    scaleLabelPrefix: '200',
    scaleLabelPluDigits: 6,
  });
  assert.equal(tooLong.status, 422);

  // ส่งมาช่องเดียวก็ต้องถูกเทียบกับค่าที่บันทึกไว้ (ตอนนี้ PLU 6 หลัก + prefix 3 หลัก = เหลือ 3)
  const onlyPrefix = await patch('/api/v1/settings', admin.token, { scaleLabelPrefix: '200' });
  assert.equal(onlyPrefix.status, 400);

  const notTwo = await patch('/api/v1/settings', admin.token, { scaleLabelPrefix: '11' });
  assert.equal(notTwo.status, 422, 'ฉลากตาชั่งตามมาตรฐาน GS1 ต้องขึ้นต้นด้วย 2');

  await patch('/api/v1/settings', admin.token, { scaleLabelPrefix: '20', scaleLabelPluDigits: 5 });
});
