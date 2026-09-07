import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/features/home/presentation/bindings/home_binding.dart';

/// เมนูที่แต่ละบทบาทเห็น เป็นกฎด้านสิทธิ์ที่ต้องไม่หลุด จึงต้องมีเทสต์คุม
void main() {
  group('เมนูนำทางตามบทบาท', () {
    test('ครัวเห็นเฉพาะจอครัวกับบัญชีของตัวเอง', () {
      final destinations = HomeBinding.destinationsForRole(UserRole.kitchen);

      expect(destinations.map((d) => d.label), ['ครัว', 'บัญชี']);
    });

    test('พนักงานเสิร์ฟไม่เห็นเมนูจัดการร้าน', () {
      final labels = HomeBinding.destinationsForRole(
        UserRole.waiter,
      ).map((d) => d.label).toList();

      expect(labels, contains('ผังโต๊ะ'));
      expect(labels, contains('ออเดอร์'));
      expect(labels, isNot(contains('พนักงาน')));
      expect(labels, isNot(contains('รายงาน')));
      expect(labels, isNot(contains('ตั้งค่า')));
    });

    test('แคชเชียร์เห็นรายงานแต่ไม่เห็นการจัดการเมนู', () {
      final labels = HomeBinding.destinationsForRole(
        UserRole.cashier,
      ).map((d) => d.label).toList();

      expect(labels, contains('รายงาน'));
      expect(labels, isNot(contains('จัดการเมนู')));
    });

    test('แอดมินเห็นทุกเมนู', () {
      final labels = HomeBinding.destinationsForRole(
        UserRole.admin,
      ).map((d) => d.label).toList();

      expect(
        labels,
        containsAll(['ภาพรวม', 'จัดการเมนู', 'พนักงาน', 'รายงาน', 'ตั้งค่า']),
      );
    });
  });
}
