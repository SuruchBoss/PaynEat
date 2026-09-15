import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_option.dart';
import 'package:payneat_pos/features/order/domain/entities/cart_line.dart';
import 'package:payneat_pos/features/order/domain/services/bill_calculator.dart';

/// เทสต์กฎการคิดเงิน — ต้องได้ผลลัพธ์ตรงกับฝั่ง backend เป๊ะ ๆ
void main() {
  const calculator = BillCalculator(vatRate: 0.07, serviceChargeRate: 0.1);

  MenuItem item(double price) =>
      MenuItem(id: 1, categoryId: 1, name: 'ทดสอบ', price: price);

  group('BillCalculator', () {
    test('คิด service charge 10% และ VAT 7% ตามลำดับที่ถูกต้อง', () {
      final bill = calculator.fromSubtotal(150);

      expect(bill.subtotal, 150);
      expect(bill.serviceCharge, 15);
      expect(bill.vat, 11.55); // 7% ของ 165
      expect(bill.total, 176.55);
    });

    test('หักส่วนลดก่อนคิด service charge และ VAT', () {
      final bill = calculator.fromSubtotal(150, discountAmount: 50);

      expect(bill.discount, 50);
      expect(bill.serviceCharge, 10);
      expect(bill.total, 117.70);
    });

    test('ส่วนลดเปอร์เซ็นต์คิดจากยอดรวมอาหาร', () {
      final bill = calculator.fromSubtotal(150, discountPercent: 10);

      expect(bill.discount, 15);
      expect(bill.serviceCharge, 13.5);
      expect(bill.total, 158.90);
    });

    test('ส่วนลดต้องไม่เกินยอดรวม', () {
      final bill = calculator.fromSubtotal(150, discountAmount: 9999);

      expect(bill.discount, 150);
      expect(bill.total, 0);
    });

    test('ส่วนลดโปรโมชันหักก่อนคิด service charge และ VAT เหมือนส่วนลดมือ', () {
      final bill = calculator.fromSubtotal(150, promotionDiscountAmount: 50);

      expect(bill.discount, 0);
      expect(bill.promotionDiscount, 50);
      expect(bill.serviceCharge, 10);
      expect(bill.total, 117.70);
    });

    test('ส่วนลดมือ + ส่วนลดโปรโมชันรวมกันได้ แต่ต้องไม่เกินยอดรวมทั้งคู่', () {
      final bill = calculator.fromSubtotal(
        150,
        discountAmount: 120,
        promotionDiscountAmount: 50,
      );

      expect(bill.discount, 120);
      expect(bill.promotionDiscount, 30); // เหลือให้หักได้แค่ 150-120=30
      expect(bill.total, 0);
    });

    test('ส่วนลดโปรโมชันต้องไม่เกินยอดรวมเช่นเดียวกับส่วนลดมือ', () {
      final bill = calculator.fromSubtotal(150, promotionDiscountAmount: 9999);

      expect(bill.promotionDiscount, 150);
      expect(bill.total, 0);
    });

    test('โหมดราคารวม VAT แล้วจะถอด VAT ออกมาแสดงแทนการบวกเพิ่ม', () {
      const inclusive = BillCalculator(
        vatRate: 0.07,
        serviceChargeRate: 0,
        vatIncluded: true,
      );
      final bill = inclusive.fromSubtotal(107);

      expect(bill.total, 107);
      expect(bill.vat, closeTo(7, 0.01));
    });

    test('ตะกร้าว่างได้ยอดเป็นศูนย์ทั้งหมด', () {
      final bill = calculator.fromCart([]);

      expect(bill.subtotal, 0);
      expect(bill.total, 0);
    });

    test('รวมราคาตัวเลือกเสริมเข้าไปในยอดต่อบรรทัด', () {
      final line = CartLine(
        menuItem: item(75),
        quantity: 2,
        selectedOptions: [
          const MenuOption(id: 1, name: 'ไข่ดาว', priceDelta: 15),
        ],
      );
      final bill = calculator.fromCart([line]);

      expect(line.unitPrice, 90);
      expect(line.lineTotal, 180);
      expect(bill.subtotal, 180);
      expect(bill.total, 211.86); // ตรงกับผลลัพธ์ที่ backend คำนวณ
    });
  });
}
