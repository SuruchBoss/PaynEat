// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/// ผลการแบ่งยอดคืนหนึ่งรอบ ทุกค่าเป็นสตางค์ ยกเว้นจำนวนแต้ม
typedef RefundSplit = ({int cashAmount, int points, int pointsValue});

/// แบ่งยอดคืนของ payment ที่ลูกค้าจ่ายด้วยเงินกับแต้ม เป็นเงินที่คืนจริงกับแต้มที่คืนให้ลูกค้า
/// (T11 #101, docs/DECISIONS.md #77 D7, #99) — mirror ของ `backend/src/modules/payments/refund.split.js`
///
/// ยอดคืน ([amount]) เป็นมูลค่าตามบิล (เงิน + มูลค่าแต้ม) แบ่งตามสัดส่วนที่ลูกค้าจ่ายมา แต้มปัดลงเป็นจำนวนเต็ม เศษคืนเป็นเงิน
/// แต่เงินที่คืนสะสมต้องไม่เกินเงินที่รับจริง คืนจนครบยอดของ payment = คืนแต้มที่ใช้ไปทั้งหมด
/// คิดจากยอดสะสม (ที่คืนไปแล้ว + รอบนี้) การคืนหลายรอบจึงรวมกันได้เท่าการคืนครั้งเดียวเสมอ
///
/// คืน `null` เมื่อแบ่งไม่ได้: เงินที่รับจริงคืนครบแล้ว ส่วนที่เหลือต้องคืนเป็นแต้ม แต่ยอดรอบนี้ไม่ใช่มูลค่าแต้มเต็มแต้ม
RefundSplit? splitRefund({
  required int paymentAmount,
  int pointsRedeemed = 0,
  int pointsRedeemedValue = 0,
  int refunded = 0,
  int pointsReturned = 0,
  int pointsValueReturned = 0,
  required int amount,
}) {
  if (pointsRedeemed <= 0 || pointsRedeemedValue <= 0) {
    return (cashAmount: amount, points: 0, pointsValue: 0);
  }

  final cashReceived = paymentAmount - pointsRedeemedValue;
  final cumulative = refunded + amount;
  int valueOf(int points) => points >= pointsRedeemed
      ? pointsRedeemedValue
      : (points * pointsRedeemedValue / pointsRedeemed).round();

  int target;
  if (cumulative >= paymentAmount) {
    target = pointsRedeemed;
  } else {
    final proportional = cumulative * pointsRedeemed ~/ paymentAmount;
    // เงินที่คืนสะสมต้องไม่เกินเงินที่รับจริง → ต้องคืนแต้มอย่างน้อยเท่านี้
    var lowest = pointsReturned;
    while (lowest < pointsRedeemed &&
        cumulative - valueOf(lowest) > cashReceived) {
      lowest += 1;
    }
    // เงินที่คืนรอบนี้ติดลบไม่ได้ → คืนแต้มรอบนี้ได้ไม่เกินยอดรอบนี้
    var highest = pointsRedeemed;
    while (highest > pointsReturned &&
        valueOf(highest) - pointsValueReturned > amount) {
      highest -= 1;
    }
    if (lowest > highest) return null;
    final floor = lowest > pointsReturned ? lowest : pointsReturned;
    target = proportional > floor ? proportional : floor;
    if (target > highest) target = highest;
  }

  final pointsValue = valueOf(target) - pointsValueReturned;
  return (
    cashAmount: amount - pointsValue,
    points: target - pointsReturned,
    pointsValue: pointsValue,
  );
}
