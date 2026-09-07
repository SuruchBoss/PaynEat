import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_option.dart';
import 'package:payneat_pos/features/order/domain/entities/cart_line.dart';

void main() {
  const padkrapao = MenuItem(id: 10, categoryId: 1, name: 'ผัดกะเพรา', price: 75);
  const spicy = MenuOption(id: 1, name: 'เผ็ดมาก');
  const egg = MenuOption(id: 2, name: 'ไข่ดาว', priceDelta: 15);

  group('CartLine', () {
    test('signature เหมือนกันเมื่อเมนู ตัวเลือก และโน้ตเหมือนกัน (ไม่สนลำดับตัวเลือก)', () {
      final first = CartLine(menuItem: padkrapao, selectedOptions: [spicy, egg]);
      final second = CartLine(menuItem: padkrapao, selectedOptions: [egg, spicy]);

      expect(first.signature, second.signature);
    });

    test('signature ต่างกันเมื่อโน้ตต่างกัน', () {
      final first = CartLine(menuItem: padkrapao, selectedOptions: [spicy]);
      final second = CartLine(
        menuItem: padkrapao,
        selectedOptions: [spicy],
        note: 'ไม่ใส่ผัก',
      );

      expect(first.signature, isNot(second.signature));
    });

    test('optionIds ส่งเฉพาะ id ของตัวเลือกที่เลือก', () {
      final line = CartLine(menuItem: padkrapao, selectedOptions: [spicy, egg]);

      expect(line.optionIds, [1, 2]);
    });

    test('copyWith เปลี่ยนจำนวนโดยไม่กระทบตัวเลือกเดิม', () {
      final line = CartLine(menuItem: padkrapao, selectedOptions: [egg]);
      final copied = line.copyWith(quantity: 3);

      expect(copied.quantity, 3);
      expect(copied.selectedOptions, [egg]);
      expect(copied.lineTotal, 270);
      expect(line.quantity, 1, reason: 'ต้นฉบับต้องไม่ถูกแก้');
    });
  });
}
