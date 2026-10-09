// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test from 'node:test';
import assert from 'node:assert/strict';
import { splitRefund } from '../src/modules/payments/refund.split.js';

// แบ่งยอดคืนเป็นเงินกับแต้มตามสัดส่วนที่ลูกค้าจ่าย (T11 #101, docs/DECISIONS.md #77 D7, #99) — ทุกค่าเป็นสตางค์ ยกเว้นจำนวนแต้ม
// บิล 100.05 ใช้ 40 แต้ม (มูลค่า 40 บาท) + เงินสด 60.05
const pointsBill = { paymentAmount: 10005, pointsRedeemed: 40, pointsRedeemedValue: 4000 };

/** คืนหลายรอบต่อกัน แล้วรวมเงินกับแต้มที่คืนทั้งหมด */
const refundInRounds = (payment, amounts) => {
  let refunded = 0;
  let pointsReturned = 0;
  let pointsValueReturned = 0;
  let cash = 0;
  for (const amount of amounts) {
    const part = splitRefund({ ...payment, refunded, pointsReturned, pointsValueReturned, amount });
    assert.ok(part, `คืน ${amount} ต้องแบ่งได้`);
    assert.ok(part.cashAmount >= 0, 'เงินที่คืนรอบหนึ่งติดลบไม่ได้');
    refunded += amount;
    pointsReturned += part.points;
    pointsValueReturned += part.pointsValue;
    cash += part.cashAmount;
  }
  return { cash, points: pointsReturned, pointsValue: pointsValueReturned };
};

test('คืนเต็มจำนวน → เงินที่รับจริงทั้งหมดกับแต้มที่ใช้ไปทั้งหมด', () => {
  assert.deepEqual(splitRefund({ ...pointsBill, amount: 10005 }), {
    cashAmount: 6005,
    points: 40,
    pointsValue: 4000,
  });
});

test('ตัวอย่างของ PO: จ่ายเงิน 60% แต้ม 40% คืน 50 บาท = เงิน 30 แต้มมูลค่า 20', () => {
  const payment = { paymentAmount: 10000, pointsRedeemed: 40, pointsRedeemedValue: 4000 };
  assert.deepEqual(splitRefund({ ...payment, amount: 5000 }), {
    cashAmount: 3000,
    points: 20,
    pointsValue: 2000,
  });
});

test('แต้มปัดลงเป็นจำนวนเต็ม เศษคืนเป็นเงิน', () => {
  // 50 × 40 / 100.05 = 19.99 แต้ม → 19 แต้ม เงิน 31
  assert.deepEqual(splitRefund({ ...pointsBill, amount: 5000 }), {
    cashAmount: 3100,
    points: 19,
    pointsValue: 1900,
  });
});

test('เงินที่คืนต้องไม่เกินเงินที่รับจริง แม้ปัดแต้มลงแล้วเงินจะเกิน', () => {
  // 100 × 40 / 100.05 = 39.98 → ปัดลงเหลือ 39 แต้ม เงิน 61 บาทเกินเงินที่รับมา 60.05 → คืนแต้ม 40 เงิน 60
  assert.deepEqual(splitRefund({ ...pointsBill, amount: 10000 }), {
    cashAmount: 6000,
    points: 40,
    pointsValue: 4000,
  });
});

test('คืนหลายรอบรวมกันได้เท่าคืนครั้งเดียว ไม่มีเศษสะสม', () => {
  for (const rounds of [
    [3000, 3000, 4005],
    [1, 1, 1, 10002],
    [2501, 2501, 2501, 2502],
  ]) {
    assert.deepEqual(refundInRounds(pointsBill, rounds), {
      cash: 6005,
      points: 40,
      pointsValue: 4000,
    });
  }
});

test('payment ที่ไม่ได้ใช้แต้มคืนเป็นเงินทั้งหมด', () => {
  assert.deepEqual(splitRefund({ paymentAmount: 10005, amount: 2500 }), {
    cashAmount: 2500,
    points: 0,
    pointsValue: 0,
  });
});

test('เงินที่รับจริงคืนครบแล้ว ยอดที่ไม่ใช่มูลค่าแต้มเต็มแต้มแบ่งไม่ได้', () => {
  // 2 แต้ม มูลค่า 1.50 (0.75/แต้ม) + เงิน 0.50 รอบแรกคืน 1.00 = 1 แต้ม + เงิน 0.25
  const payment = { paymentAmount: 200, pointsRedeemed: 2, pointsRedeemedValue: 150 };
  const first = splitRefund({ ...payment, amount: 100 });
  assert.deepEqual(first, { cashAmount: 25, points: 1, pointsValue: 75 });
  // รอบสอง 0.30: เงินเหลือคืนได้ 0.25 ที่เหลือต้องเป็นแต้มเต็มแต้ม (0.75) ซึ่งเกินยอดรอบนี้
  assert.equal(
    splitRefund({
      ...payment,
      refunded: 100,
      pointsReturned: 1,
      pointsValueReturned: 75,
      amount: 30,
    }),
    null,
  );
  // คืนส่วนที่เหลือทั้งหมดได้เสมอ
  assert.deepEqual(
    splitRefund({
      ...payment,
      refunded: 100,
      pointsReturned: 1,
      pointsValueReturned: 75,
      amount: 100,
    }),
    { cashAmount: 25, points: 1, pointsValue: 75 },
  );
});
