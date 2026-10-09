// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/features/payment/domain/services/refund_split.dart';

// แบ่งยอดคืนเป็นเงินกับแต้มตามสัดส่วนที่ลูกค้าจ่าย (T11 #101, docs/DECISIONS.md #77 D7, #100) — เคสเดียวกับ
// backend/tests/refund-split.test.js ทุกค่าเป็นสตางค์ ยกเว้นจำนวนแต้ม
// บิล 100.05 ใช้ 40 แต้ม (มูลค่า 40 บาท) + เงินสด 60.05
RefundSplit? pointsBill(
  int amount, {
  int refunded = 0,
  int pointsReturned = 0,
  int pointsValueReturned = 0,
}) => splitRefund(
  paymentAmount: 10005,
  pointsRedeemed: 40,
  pointsRedeemedValue: 4000,
  refunded: refunded,
  pointsReturned: pointsReturned,
  pointsValueReturned: pointsValueReturned,
  amount: amount,
);

/// คืนหลายรอบต่อกัน แล้วรวมเงินกับแต้มที่คืนทั้งหมด
({int cash, int points, int pointsValue}) refundInRounds(List<int> amounts) {
  var refunded = 0;
  var pointsReturned = 0;
  var pointsValueReturned = 0;
  var cash = 0;
  for (final amount in amounts) {
    final part = pointsBill(
      amount,
      refunded: refunded,
      pointsReturned: pointsReturned,
      pointsValueReturned: pointsValueReturned,
    );
    expect(part, isNotNull, reason: 'คืน $amount ต้องแบ่งได้');
    expect(part!.cashAmount, greaterThanOrEqualTo(0));
    refunded += amount;
    pointsReturned += part.points;
    pointsValueReturned += part.pointsValue;
    cash += part.cashAmount;
  }
  return (cash: cash, points: pointsReturned, pointsValue: pointsValueReturned);
}

void main() {
  test('คืนเต็มจำนวน → เงินที่รับจริงทั้งหมดกับแต้มที่ใช้ไปทั้งหมด', () {
    expect(pointsBill(10005), (
      cashAmount: 6005,
      points: 40,
      pointsValue: 4000,
    ));
  });

  test(
    'ตัวอย่างของ PO: จ่ายเงิน 60% แต้ม 40% คืน 50 บาท = เงิน 30 แต้มมูลค่า 20',
    () {
      expect(
        splitRefund(
          paymentAmount: 10000,
          pointsRedeemed: 40,
          pointsRedeemedValue: 4000,
          amount: 5000,
        ),
        (cashAmount: 3000, points: 20, pointsValue: 2000),
      );
    },
  );

  test('แต้มปัดลงเป็นจำนวนเต็ม เศษคืนเป็นเงิน', () {
    expect(pointsBill(5000), (cashAmount: 3100, points: 19, pointsValue: 1900));
  });

  test('เงินที่คืนต้องไม่เกินเงินที่รับจริง แม้ปัดแต้มลงแล้วเงินจะเกิน', () {
    expect(pointsBill(10000), (
      cashAmount: 6000,
      points: 40,
      pointsValue: 4000,
    ));
  });

  test('คืนหลายรอบรวมกันได้เท่าคืนครั้งเดียว ไม่มีเศษสะสม', () {
    for (final rounds in [
      [3000, 3000, 4005],
      [1, 1, 1, 10002],
      [2501, 2501, 2501, 2502],
    ]) {
      expect(refundInRounds(rounds), (
        cash: 6005,
        points: 40,
        pointsValue: 4000,
      ));
    }
  });

  test('payment ที่ไม่ได้ใช้แต้มคืนเป็นเงินทั้งหมด', () {
    expect(splitRefund(paymentAmount: 10005, amount: 2500), (
      cashAmount: 2500,
      points: 0,
      pointsValue: 0,
    ));
  });

  test('เงินที่รับจริงคืนครบแล้ว ยอดที่ไม่ใช่มูลค่าแต้มเต็มแต้มแบ่งไม่ได้', () {
    RefundSplit? small(
      int amount, {
      int refunded = 0,
      int pointsReturned = 0,
      int pointsValueReturned = 0,
    }) => splitRefund(
      paymentAmount: 200,
      pointsRedeemed: 2,
      pointsRedeemedValue: 150,
      refunded: refunded,
      pointsReturned: pointsReturned,
      pointsValueReturned: pointsValueReturned,
      amount: amount,
    );
    expect(small(100), (cashAmount: 25, points: 1, pointsValue: 75));
    expect(
      small(30, refunded: 100, pointsReturned: 1, pointsValueReturned: 75),
      isNull,
    );
    expect(
      small(100, refunded: 100, pointsReturned: 1, pointsValueReturned: 75),
      (cashAmount: 25, points: 1, pointsValue: 75),
    );
  });
}
