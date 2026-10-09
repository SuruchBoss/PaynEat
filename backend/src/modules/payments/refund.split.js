// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/**
 * แบ่งยอดคืนของ payment ที่ลูกค้าจ่ายด้วยเงินกับแต้ม เป็นเงินที่คืนจริงกับแต้มที่คืนให้ลูกค้า (T11 #101, docs/DECISIONS.md #77 D7, #99)
 *
 * ยอดคืน (`amount`) เป็นมูลค่าตามบิลเหมือนเดิม (เงิน + มูลค่าแต้ม) แบ่งตามสัดส่วนที่ลูกค้าจ่ายมา: payment ที่จ่ายเงิน 60% แต้ม 40%
 * คืน 50 บาท = เงิน 30 แต้มมูลค่า 20 แต้มปัดลงเป็นจำนวนเต็ม เศษคืนเป็นเงิน แต่เงินที่คืนสะสมต้องไม่เกินเงินที่รับจริง
 * คืนจนครบยอดของ payment = คืนแต้มที่ใช้ไปทั้งหมด
 *
 * คิดจากยอดสะสม (ที่คืนไปแล้ว + รอบนี้) ไม่ใช่ทีละรอบ การคืนหลายรอบจึงรวมกันได้เท่าการคืนครั้งเดียวเสมอ ไม่มีเศษสะสม
 * ทุกค่าเป็นสตางค์ ยกเว้นจำนวนแต้ม
 *
 * คืน `null` เมื่อแบ่งไม่ได้: เงินที่รับจริงคืนครบแล้ว ส่วนที่เหลือต้องคืนเป็นแต้ม แต่ยอดรอบนี้ไม่ใช่มูลค่าแต้มเต็มแต้ม
 */
export const splitRefund = ({
  paymentAmount,
  pointsRedeemed = 0,
  pointsRedeemedValue = 0,
  refunded = 0,
  pointsReturned = 0,
  pointsValueReturned = 0,
  amount,
}) => {
  if (pointsRedeemed <= 0 || pointsRedeemedValue <= 0) {
    return { cashAmount: amount, points: 0, pointsValue: 0 };
  }

  const cashReceived = paymentAmount - pointsRedeemedValue;
  const cumulative = refunded + amount;
  // มูลค่าของแต้มที่คืนสะสม t แต้ม — แต้มทั้งหมดมีมูลค่าเท่าที่บันทึกไว้ตอนจ่ายพอดี
  const valueOf = (points) =>
    points >= pointsRedeemed
      ? pointsRedeemedValue
      : Math.round((points * pointsRedeemedValue) / pointsRedeemed);

  let target;
  if (cumulative >= paymentAmount) {
    target = pointsRedeemed;
  } else {
    // ตามสัดส่วน ปัดลงเป็นแต้มเต็ม
    const proportional = Math.floor((cumulative * pointsRedeemed) / paymentAmount);
    // เงินที่คืนสะสมต้องไม่เกินเงินที่รับจริง → ต้องคืนแต้มอย่างน้อยเท่านี้
    let lowest = pointsReturned;
    while (lowest < pointsRedeemed && cumulative - valueOf(lowest) > cashReceived) lowest += 1;
    // เงินที่คืนรอบนี้ติดลบไม่ได้ → คืนแต้มรอบนี้ได้ไม่เกินยอดรอบนี้
    let highest = pointsRedeemed;
    while (highest > pointsReturned && valueOf(highest) - pointsValueReturned > amount)
      highest -= 1;
    if (lowest > highest) return null;
    target = Math.min(Math.max(proportional, lowest, pointsReturned), highest);
  }

  const pointsValue = valueOf(target) - pointsValueReturned;
  return { cashAmount: amount - pointsValue, points: target - pointsReturned, pointsValue };
};

export default splitRefund;
