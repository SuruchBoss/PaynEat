import test from 'node:test';
import assert from 'node:assert/strict';
import {
  evaluatePromotion,
  findBestAutoPromotion,
  describeIneligibility,
} from '../src/modules/orders/promotion.engine.js';

const basePromotion = (overrides = {}) => ({
  id: 1,
  name: 'ทดสอบ',
  type: 'percent',
  value: 1000, // 10%
  code: null,
  conditions_json: '{}',
  is_active: true,
  valid_from: null,
  valid_to: null,
  ...overrides,
});

const items = [
  { id: 1, menu_item_id: 10, category_id: 1, line_total: 10000, quantity: 1, status: 'pending' },
  { id: 2, menu_item_id: 20, category_id: 2, line_total: 5000, quantity: 1, status: 'pending' },
];

test('โปรโมชันเปอร์เซ็นต์ ไม่จำกัดเมนู ใช้กับ subtotal ทั้งบิล', () => {
  const result = evaluatePromotion(basePromotion(), { items, now: new Date() });
  assert.equal(result.discountAmount, 1500); // 10% ของ 150 บาท
});

test('โปรโมชันจำนวนเงินคงที่ ถูกจำกัดไม่ให้เกิน subtotal ที่เข้าเงื่อนไข', () => {
  const promotion = basePromotion({ type: 'amount', value: 99999 });
  const result = evaluatePromotion(promotion, { items, now: new Date() });
  assert.equal(result.discountAmount, 15000); // ชนเพดาน subtotal ทั้งบิล
});

test('โปรโมชัน BOGO ให้ของถูกกว่าฟรีเมื่อซื้อครบคู่', () => {
  const bogoItems = [
    { id: 1, menu_item_id: 10, category_id: 1, line_total: 6000, quantity: 2, status: 'pending' },
  ];
  const promotion = basePromotion({ type: 'bogo', value: 0 });
  const result = evaluatePromotion(promotion, { items: bogoItems, now: new Date() });
  assert.equal(result.discountAmount, 3000); // 1 ใน 2 ชิ้น (ราคาต่อชิ้น 30 บาท) ฟรี
});

test('BOGO ข้ามเมนูที่เข้าเงื่อนไข เอาชิ้นที่ถูกที่สุดฟรีก่อน', () => {
  const bogoItems = [
    { id: 1, menu_item_id: 10, category_id: 1, line_total: 8000, quantity: 1, status: 'pending' },
    { id: 2, menu_item_id: 20, category_id: 1, line_total: 3000, quantity: 1, status: 'pending' },
  ];
  const promotion = basePromotion({ type: 'bogo', value: 0 });
  const result = evaluatePromotion(promotion, { items: bogoItems, now: new Date() });
  assert.equal(result.discountAmount, 3000); // ชิ้นละ 80/30 บาท → ฟรีตัวถูกกว่า (30 บาท)
});

test('ยอดบิลไม่ถึงขั้นต่ำ → ใช้ไม่ได้', () => {
  const promotion = basePromotion({ conditions_json: JSON.stringify({ minSubtotal: 20000 }) });
  const result = evaluatePromotion(promotion, { items, now: new Date() });
  assert.equal(result, null);
});

test('จำกัดเฉพาะหมวดหมู่ — คิดส่วนลดจาก subtotal เฉพาะรายการที่เข้าเงื่อนไข', () => {
  const promotion = basePromotion({ conditions_json: JSON.stringify({ categoryIds: [1] }) });
  const result = evaluatePromotion(promotion, { items, now: new Date() });
  assert.equal(result.discountAmount, 1000); // 10% ของ 100 บาท (แค่รายการ category_id=1)
});

test('จำกัดเฉพาะเมนู — ไม่มีรายการที่เข้าเงื่อนไขเลยในบิลนี้ → ใช้ไม่ได้', () => {
  const promotion = basePromotion({ conditions_json: JSON.stringify({ menuItemIds: [999] }) });
  const result = evaluatePromotion(promotion, { items, now: new Date() });
  assert.equal(result, null);
});

test('นอกช่วงวันในสัปดาห์ที่กำหนด → ใช้ไม่ได้', () => {
  const now = new Date('2026-09-14T12:00:00'); // วันจันทร์ (getDay()=1)
  const promotion = basePromotion({ conditions_json: JSON.stringify({ daysOfWeek: [0, 6] }) });
  const result = evaluatePromotion(promotion, { items, now });
  assert.equal(result, null);
});

test('นอกช่วงเวลาที่กำหนด (happy hour) → ใช้ไม่ได้', () => {
  const now = new Date('2026-09-14T20:00:00');
  const promotion = basePromotion({
    conditions_json: JSON.stringify({ startTime: '14:00', endTime: '17:00' }),
  });
  const result = evaluatePromotion(promotion, { items, now });
  assert.equal(result, null);
});

test('ในช่วงเวลาที่กำหนด → ใช้ได้', () => {
  const now = new Date('2026-09-14T15:00:00');
  const promotion = basePromotion({
    conditions_json: JSON.stringify({ startTime: '14:00', endTime: '17:00' }),
  });
  const result = evaluatePromotion(promotion, { items, now });
  assert.ok(result);
});

test('นอกช่วง valid_from/valid_to ของแคมเปญ → ใช้ไม่ได้', () => {
  const promotion = basePromotion({ valid_from: '2026-01-01', valid_to: '2026-01-31' });
  const result = evaluatePromotion(promotion, { items, now: new Date('2026-09-14T12:00:00') });
  assert.equal(result, null);
});

test('ปิดใช้งาน (is_active=false) → ใช้ไม่ได้แม้เข้าเงื่อนไขอื่นครบ', () => {
  const promotion = basePromotion({ is_active: false });
  const result = evaluatePromotion(promotion, { items, now: new Date() });
  assert.equal(result, null);
});

test('findBestAutoPromotion เลือกตัวที่ให้ส่วนลดมากที่สุดในบรรดาที่ไม่ใช้โค้ด', () => {
  const promotions = [
    basePromotion({ id: 1, type: 'percent', value: 500 }), // 5% = 750
    basePromotion({ id: 2, type: 'amount', value: 2000 }), // 20 บาท
  ];
  const best = findBestAutoPromotion(promotions, { items, now: new Date() });
  assert.equal(best.promotionId, 2);
  assert.equal(best.discountAmount, 2000);
});

test('findBestAutoPromotion ข้ามโปรโมชันที่ต้องใช้โค้ด แม้ให้ส่วนลดมากกว่า', () => {
  const promotions = [
    basePromotion({ id: 1, type: 'percent', value: 500 }),
    basePromotion({ id: 2, type: 'amount', value: 99999, code: 'BIGDEAL' }),
  ];
  const best = findBestAutoPromotion(promotions, { items, now: new Date() });
  assert.equal(best.promotionId, 1);
});

test('findBestAutoPromotion คืน null ถ้าไม่มีโปรโมชันไหนเข้าเงื่อนไขเลย', () => {
  const promotions = [basePromotion({ is_active: false })];
  const best = findBestAutoPromotion(promotions, { items, now: new Date() });
  assert.equal(best, null);
});

test('describeIneligibility บอกเหตุผลเฉพาะเจาะจงเมื่อโค้ดใช้ไม่ได้', () => {
  assert.equal(
    describeIneligibility(basePromotion({ is_active: false }), { items, now: new Date() }),
    'โค้ดนี้ถูกปิดใช้งานแล้ว',
  );
  assert.equal(
    describeIneligibility(basePromotion({ valid_to: '2020-01-01' }), { items, now: new Date() }),
    'โค้ดนี้หมดอายุหรือยังไม่เริ่มใช้งาน',
  );
  assert.equal(
    describeIneligibility(
      basePromotion({ conditions_json: JSON.stringify({ minSubtotal: 999999 }) }),
      { items, now: new Date() },
    ),
    'ยอดบิลยังไม่ถึงขั้นต่ำสำหรับโค้ดนี้',
  );
  assert.equal(
    describeIneligibility(
      basePromotion({ conditions_json: JSON.stringify({ menuItemIds: [999] }) }),
      { items, now: new Date() },
    ),
    'บิลนี้ไม่มีเมนูที่ร่วมรายการกับโค้ดนี้',
  );
  assert.equal(describeIneligibility(basePromotion(), { items, now: new Date() }), null);
});
