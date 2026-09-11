import { sumActiveSubtotal } from './order.calculator.js';

/**
 * ตรรกะจับคู่โปรโมชันกับออเดอร์ — ฟังก์ชันบริสุทธิ์ทั้งหมด แยกจาก order.calculator.js
 * เพราะเป็นการ "ตัดสินใจว่าใช้โปรโมชันไหนได้บ้าง" ไม่ใช่ตรรกะคำนวณเงินโดยตรง
 * (calculator.js รับผลลัพธ์ promotionDiscountAmount ไปรวมกับส่วนลดมือเท่านั้น)
 *
 * ไม่มีการจำกัดโปรโมชันซ้อนกันหลายใบ — ออเดอร์หนึ่งใช้ได้สูงสุด 1 โปรโมชัน (auto หรือใส่โค้ด)
 * เพื่อไม่ให้ตรรกะซับซ้อนเกินจำเป็นในเวอร์ชันแรก
 */

export const parseConditions = (conditionsJson) => {
  try {
    return JSON.parse(conditionsJson || '{}');
  } catch {
    return {};
  }
};

const isWithinValidity = (promotion, now) => {
  if (promotion.valid_from && now < new Date(`${promotion.valid_from}T00:00:00`)) return false;
  if (promotion.valid_to && now > new Date(`${promotion.valid_to}T23:59:59`)) return false;
  return true;
};

const isWithinDayTime = (conditions, now) => {
  if (conditions.daysOfWeek?.length && !conditions.daysOfWeek.includes(now.getDay())) {
    return false;
  }
  if (conditions.startTime || conditions.endTime) {
    const hhmm = now.toTimeString().slice(0, 5);
    if (conditions.startTime && hhmm < conditions.startTime) return false;
    if (conditions.endTime && hhmm > conditions.endTime) return false;
  }
  return true;
};

/** รายการที่เข้าเงื่อนไขหมวดหมู่/เมนูของโปรโมชัน — ไม่ระบุเลย = ทั้งบิล */
const matchingItems = (items, conditions) => {
  const { categoryIds, menuItemIds } = conditions;
  if (!categoryIds?.length && !menuItemIds?.length) return items;
  return items.filter(
    (item) =>
      (menuItemIds?.length && menuItemIds.includes(item.menu_item_id)) ||
      (categoryIds?.length && categoryIds.includes(item.category_id)),
  );
};

/** ส่วนลด "ซื้อ 1 แถม 1" — กระจายเป็นราคาต่อชิ้น เรียงถูกไปแพง แล้วให้ครึ่งที่ถูกกว่าฟรี */
const calculateBogoDiscount = (items) => {
  const unitPrices = [];
  for (const item of items) {
    const lineTotal = Number(item.line_total ?? item.lineTotal ?? 0);
    const quantity = Number(item.quantity) || 0;
    if (quantity <= 0) continue;
    const perUnit = Math.round(lineTotal / quantity);
    for (let i = 0; i < quantity; i += 1) unitPrices.push(perUnit);
  }
  unitPrices.sort((a, b) => a - b);
  const freeCount = Math.floor(unitPrices.length / 2);
  return unitPrices.slice(0, freeCount).reduce((acc, price) => acc + price, 0);
};

/**
 * ประเมินโปรโมชันเดียวกับออเดอร์ — คืน `{ promotionId, name, code, discountAmount }`
 * ถ้าใช้ได้ หรือ `null` ถ้าไม่เข้าเงื่อนไขใดเงื่อนไขหนึ่ง
 */
export const evaluatePromotion = (promotion, { items, now = new Date() }) => {
  if (!promotion.is_active) return null;
  if (!isWithinValidity(promotion, now)) return null;

  const conditions = parseConditions(promotion.conditions_json);
  if (!isWithinDayTime(conditions, now)) return null;

  const subtotal = sumActiveSubtotal(items);
  if (conditions.minSubtotal && subtotal < conditions.minSubtotal) return null;

  const active = items.filter((item) => item.status !== 'cancelled');
  const matched = matchingItems(active, conditions);
  if (matched.length === 0) return null;

  const eligibleSubtotal = sumActiveSubtotal(matched);
  if (eligibleSubtotal <= 0) return null;

  let discountAmount = 0;
  if (promotion.type === 'percent') {
    const percent = Math.min(Math.max(Number(promotion.value), 0), 10000);
    discountAmount = Math.round((eligibleSubtotal * percent) / 10000);
  } else if (promotion.type === 'amount') {
    discountAmount = Math.max(Number(promotion.value), 0);
  } else if (promotion.type === 'bogo') {
    discountAmount = calculateBogoDiscount(matched);
  }
  discountAmount = Math.min(discountAmount, eligibleSubtotal);
  if (discountAmount <= 0) return null;

  return {
    promotionId: promotion.id,
    name: promotion.name,
    code: promotion.code ?? null,
    discountAmount,
  };
};

/** เลือกโปรโมชันที่ "ไม่ต้องใส่โค้ด" ที่ให้ส่วนลดมากที่สุดในบรรดาที่เข้าเงื่อนไข */
export const findBestAutoPromotion = (promotions, ctx) => {
  let best = null;
  for (const promotion of promotions) {
    if (promotion.code) continue;
    const result = evaluatePromotion(promotion, ctx);
    if (result && (!best || result.discountAmount > best.discountAmount)) best = result;
  }
  return best;
};

/**
 * ใช้ตอนลูกค้ากรอกโค้ดเอง — บอกเหตุผลที่ชัดเจนว่าทำไมใช้ไม่ได้ (ต่างจาก `evaluatePromotion`
 * ที่แค่คืน null เพราะใช้กับการหาโปรโมชัน auto ที่ไม่ต้องอธิบายเหตุผลให้ผู้ใช้เห็น)
 * คืน `null` ถ้าใช้ได้ปกติ หรือ string อธิบายเหตุผลถ้าใช้ไม่ได้
 */
export const describeIneligibility = (promotion, { items, now = new Date() }) => {
  if (!promotion.is_active) return 'โค้ดนี้ถูกปิดใช้งานแล้ว';
  if (!isWithinValidity(promotion, now)) return 'โค้ดนี้หมดอายุหรือยังไม่เริ่มใช้งาน';

  const conditions = parseConditions(promotion.conditions_json);
  if (!isWithinDayTime(conditions, now)) return 'ไม่ใช่ช่วงเวลาที่ร่วมรายการของโค้ดนี้';

  const subtotal = sumActiveSubtotal(items);
  if (conditions.minSubtotal && subtotal < conditions.minSubtotal) {
    return 'ยอดบิลยังไม่ถึงขั้นต่ำสำหรับโค้ดนี้';
  }

  const active = items.filter((item) => item.status !== 'cancelled');
  const matched = matchingItems(active, conditions);
  if (matched.length === 0) return 'บิลนี้ไม่มีเมนูที่ร่วมรายการกับโค้ดนี้';

  return null;
};

export default { evaluatePromotion, findBestAutoPromotion, describeIneligibility };
