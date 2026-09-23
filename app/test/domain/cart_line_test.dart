import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_option.dart';
import 'package:payneat_pos/features/order/domain/entities/cart_line.dart';

void main() {
  const padkrapao = MenuItem(
    id: 10,
    categoryId: 1,
    name: 'ผัดกะเพรา',
    price: 75,
  );
  const spicy = MenuOption(id: 1, name: 'เผ็ดมาก');
  const egg = MenuOption(id: 2, name: 'ไข่ดาว', priceDelta: 15);

  group('CartLine', () {
    test(
      'signature เหมือนกันเมื่อเมนู ตัวเลือก และโน้ตเหมือนกัน (ไม่สนลำดับตัวเลือก)',
      () {
        final first = CartLine(
          menuItem: padkrapao,
          selectedOptions: [spicy, egg],
        );
        final second = CartLine(
          menuItem: padkrapao,
          selectedOptions: [egg, spicy],
        );

        expect(first.signature, second.signature);
      },
    );

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

  // ขายตามน้ำหนัก (ดู docs/tickets/18-sell-by-weight.md, docs/DECISIONS.md #48)
  group('CartLine ขายตามน้ำหนัก', () {
    const ribeye = MenuItem(
      id: 20,
      categoryId: 8,
      name: 'ริบอาย',
      price: 890,
      soldByWeight: true,
    );
    const marinade = MenuOption(id: 5, name: 'หมักซอส', priceDelta: 40);

    test('ราคา = ราคาต่อกิโล × กรัม / 1000 ปัดเป็นสตางค์', () {
      final line = CartLine(menuItem: ribeye, weightGrams: 485);

      expect(line.isWeighed, isTrue);
      expect(line.lineTotal, 431.65);
    });

    test('ตัวเลือกเสริมของสินค้าชั่งน้ำหนักคิดต่อกิโลด้วย', () {
      final line = CartLine(
        menuItem: ribeye,
        weightGrams: 485,
        selectedOptions: [marinade],
      );

      // (890 + 40) × 0.485 = 451.05
      expect(line.lineTotal, 451.05);
    });

    test('คิดเป็นสตางค์เต็มก่อนปัด — ตรงกับ backend แม้ราคามีเศษสตางค์', () {
      const odd = MenuItem(
        id: 21,
        categoryId: 8,
        name: 'เนื้อบด',
        price: 123.45,
        soldByWeight: true,
      );

      // 12345 สตางค์ × 333 / 1000 = 4110.885 → 4111 สตางค์
      expect(CartLine(menuItem: odd, weightGrams: 333).lineTotal, 41.11);
    });

    test('สองถุงน้ำหนักเท่ากันไม่ถูกรวมเป็นบรรทัดเดียว', () {
      final first = CartLine(menuItem: ribeye, weightGrams: 500);
      final second = CartLine(menuItem: ribeye, weightGrams: 500);

      expect(first.signature, isNot(second.signature));
    });

    test('copyWith เปลี่ยนน้ำหนักได้ ราคาเปลี่ยนตาม', () {
      final line = CartLine(menuItem: ribeye, weightGrams: 500);

      expect(line.copyWith(weightGrams: 1000).lineTotal, 890);
      expect(line.lineTotal, 445);
    });
  });
}
