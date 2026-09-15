import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/features/home/presentation/bindings/home_binding.dart';

/// เมนูที่แต่ละบทบาทเห็น เป็นกฎด้านสิทธิ์ที่ต้องไม่หลุด จึงต้องมีเทสต์คุม
void main() {
  group('เมนูนำทางตามบทบาท', () {
    // d.label เก็บ "คีย์คำแปล" ดิบไว้ (ไม่ใช่ข้อความไทย) เพราะ HomeDestination
    // เป็น const — เรียก .tr ตอนสร้าง object ไม่ได้ ต้อง resolve ตอนแสดงผลจริง
    test('ครัวเห็นเฉพาะจอครัวกับบัญชีของตัวเอง', () {
      final destinations = HomeBinding.destinationsForRole(UserRole.kitchen);

      expect(destinations.map((d) => d.label), [
        'home_nav_kitchen',
        'home_nav_profile',
      ]);
    });

    test('พนักงานเสิร์ฟไม่เห็นเมนูจัดการร้าน', () {
      final labels = HomeBinding.destinationsForRole(
        UserRole.waiter,
      ).map((d) => d.label).toList();

      expect(labels, contains('home_nav_tables'));
      expect(labels, contains('home_nav_orders'));
      expect(labels, isNot(contains('home_nav_staff')));
      expect(labels, isNot(contains('home_nav_reports')));
      expect(labels, isNot(contains('home_nav_settings')));
    });

    test('แคชเชียร์เห็นรายงานแต่ไม่เห็นการจัดการเมนู', () {
      final labels = HomeBinding.destinationsForRole(
        UserRole.cashier,
      ).map((d) => d.label).toList();

      expect(labels, contains('home_nav_reports'));
      expect(labels, isNot(contains('home_nav_menu')));
    });

    test('แอดมินเห็นทุกเมนู', () {
      final labels = HomeBinding.destinationsForRole(
        UserRole.admin,
      ).map((d) => d.label).toList();

      expect(
        labels,
        containsAll([
          'home_nav_dashboard',
          'home_nav_menu',
          'home_nav_staff',
          'home_nav_reports',
          'home_nav_settings',
        ]),
      );
    });
  });
}
