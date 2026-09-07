import test from 'node:test';
import assert from 'node:assert/strict';
import { calculateBill } from '../src/modules/orders/order.calculator.js';

const items = [
  { line_total: 10000, status: 'pending' },
  { line_total: 5000, status: 'pending' },
];

test('คำนวณบิลพื้นฐาน: subtotal + service charge 10% + VAT 7%', () => {
  const bill = calculateBill({ items, vatRate: 0.07, serviceChargeRate: 0.1 });

  assert.equal(bill.subtotal, 15000); // 150.00 บาท
  assert.equal(bill.serviceCharge, 1500); //  15.00 บาท
  assert.equal(bill.vat, 1155); //  11.55 บาท (7% ของ 165)
  assert.equal(bill.total, 17655); // 176.55 บาท
});

test('ไม่นับรายการที่ถูกยกเลิกเข้ายอดรวม', () => {
  const bill = calculateBill({
    items: [...items, { line_total: 99900, status: 'cancelled' }],
    vatRate: 0.07,
    serviceChargeRate: 0.1,
  });
  assert.equal(bill.subtotal, 15000);
});

test('ส่วนลดแบบจำนวนเงินถูกหักก่อนคิด service charge และ VAT', () => {
  const bill = calculateBill({
    items,
    discountType: 'amount',
    discountValue: 5000,
    vatRate: 0.07,
    serviceChargeRate: 0.1,
  });

  assert.equal(bill.discountAmount, 5000);
  assert.equal(bill.serviceCharge, 1000); // 10% ของ 100 บาท
  assert.equal(bill.total, 11770); // 100 + 10 + 7.70
});

test('ส่วนลดแบบเปอร์เซ็นต์ (เก็บเป็น basis point: 10% = 1000)', () => {
  const bill = calculateBill({
    items,
    discountType: 'percent',
    discountValue: 1000,
    vatRate: 0.07,
    serviceChargeRate: 0.1,
  });
  assert.equal(bill.discountAmount, 1500); // 10% ของ 150 บาท
});

test('ส่วนลดต้องไม่เกินยอดรวม', () => {
  const bill = calculateBill({ items, discountType: 'amount', discountValue: 999999 });
  assert.equal(bill.discountAmount, 15000);
  assert.equal(bill.total, 0);
});

test('โหมดราคารวม VAT แล้ว จะถอด VAT ออกมาแสดงแทนการบวกเพิ่ม', () => {
  const bill = calculateBill({
    items,
    vatRate: 0.07,
    serviceChargeRate: 0,
    vatIncluded: true,
  });
  assert.equal(bill.total, 15000);
  assert.equal(bill.vat, 15000 - Math.round(15000 / 1.07));
});
