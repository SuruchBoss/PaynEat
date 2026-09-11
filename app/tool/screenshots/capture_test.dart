@Tags(['screenshots'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/app/routes/app_routes.dart';
import 'package:payneat_pos/app/theme/app_colors.dart';
import 'package:payneat_pos/features/home/presentation/controllers/home_controller.dart';

import 'screenshot_harness.dart';

/// ถ่ายภาพหน้าจอทุกหน้าของแอปเพื่อใช้ทำเอกสารประกอบผลงาน
///
/// รันด้วย:
/// ```
/// flutter test --update-goldens --dart-define=DEMO_MODE=true tool/screenshots/capture_test.dart
/// ```
///
/// ภาพจะถูกบันทึกลง tool/screenshots/images/
void main() {
  late ({int openOrderId, int kitchenOrderId, int paidOrderId}) ids;

  setUpAll(() async {
    await ScreenshotHarness.loadFonts();
    // ต้องตรึงเวลาก่อน seed เสมอ ข้อมูลสาธิตประทับเวลาตอนถูกสร้างขึ้นมา
    ScreenshotHarness.freezeClock();
    ids = ScreenshotHarness.seedScenario();
  });

  tearDownAll(ScreenshotHarness.unfreezeClock);

  // ---------------------------------------------------------------------
  // มือถือ — พนักงานเสิร์ฟ
  // ---------------------------------------------------------------------
  group('มือถือ (พนักงานเสิร์ฟ)', () {
    testWidgets('01 หน้าเข้าสู่ระบบ', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.capture(tester, 'phone-01-login');
    });

    testWidgets('02 ผังโต๊ะ', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');
      await ScreenshotHarness.capture(tester, 'phone-02-tables');
    });

    testWidgets('03 หน้ารับออเดอร์', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');

      unawaited(
        Get.toNamed<void>(
          AppRoutes.newOrder,
          arguments: {'tableId': 3, 'tableName': 'A3', 'seats': 4},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-03-order-taking');
    });

    testWidgets('04 เลือกตัวเลือกเสริม', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');

      unawaited(
        Get.toNamed<void>(
          AppRoutes.newOrder,
          arguments: {'tableId': 3, 'tableName': 'A3', 'seats': 4},
        ),
      );
      await ScreenshotHarness.settle(tester);

      await tester.tap(find.text('ผัดกะเพราหมูสับ').first);
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-04-option-sheet');
    });

    testWidgets('05 ตะกร้าพร้อมยอดบิล', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');

      unawaited(
        Get.toNamed<void>(
          AppRoutes.newOrder,
          arguments: {'tableId': 3, 'tableName': 'A3', 'seats': 4},
        ),
      );
      await ScreenshotHarness.settle(tester);

      await tester.tap(find.text('ข้าวหมูกรอบ').first);
      await ScreenshotHarness.settle(tester);
      await tester.tap(find.text('ราดหน้าหมูหมัก').first);
      await ScreenshotHarness.settle(tester);

      await tester.tap(find.byIcon(Icons.shopping_basket_outlined).first);
      await ScreenshotHarness.settle(tester);

      await ScreenshotHarness.capture(tester, 'phone-05-cart');
    });

    testWidgets('06 รายละเอียดออเดอร์', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');

      unawaited(
        Get.toNamed<void>(
          AppRoutes.orderDetail,
          arguments: {'orderId': ids.kitchenOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-06-order-detail');
    });

    testWidgets('07 รายการออเดอร์', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');

      Get.find<HomeController>().changeTab(1);
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-07-orders');
    });

    testWidgets('08 จอครัวบนมือถือ', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'kitchen', 'kitchen123');
      await ScreenshotHarness.capture(tester, 'phone-08-kitchen');
    });

    testWidgets('09 หน้าเก็บเงิน', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');

      unawaited(
        Get.toNamed<void>(
          AppRoutes.checkout,
          arguments: {'orderId': ids.openOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-09-checkout');
    });

    testWidgets('10 ใบเสร็จ', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');

      unawaited(
        Get.toNamed<void>(
          AppRoutes.receipt,
          arguments: {'orderId': ids.paidOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-10-receipt');
    });

    testWidgets('11 โปรไฟล์ผู้ใช้', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');

      Get.find<HomeController>().changeTab(3);
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-11-profile');
    });
  });

  // ---------------------------------------------------------------------
  // แท็บเล็ต — จุดรับออเดอร์และจอครัว
  // ---------------------------------------------------------------------
  group('แท็บเล็ต', () {
    testWidgets('12 ผังโต๊ะ', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.tablet);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');
      await ScreenshotHarness.capture(tester, 'tablet-12-tables');
    });

    testWidgets('13 รับออเดอร์แบบสองคอลัมน์', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.tablet);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');

      unawaited(
        Get.toNamed<void>(
          AppRoutes.newOrder,
          arguments: {'tableId': 4, 'tableName': 'A4', 'seats': 4},
        ),
      );
      await ScreenshotHarness.settle(tester);

      await tester.tap(find.text('ข้าวผัดกุ้ง').first);
      await ScreenshotHarness.settle(tester);
      // ปุ่มยืนยันในแผ่นเลือกตัวเลือกมีราคาต่อท้าย จึงจับด้วยข้อความบางส่วน
      await tester.tap(find.textContaining('เพิ่มลงออเดอร์').first);
      await ScreenshotHarness.settle(tester);
      await tester.tap(find.text('ข้าวหมูกรอบ').first);
      await ScreenshotHarness.settle(tester);

      await ScreenshotHarness.capture(tester, 'tablet-13-order-taking');
    });

    testWidgets('14 จอครัว 3 คอลัมน์', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.tablet);
      await ScreenshotHarness.loginAs(tester, 'kitchen', 'kitchen123');
      await ScreenshotHarness.capture(tester, 'tablet-14-kitchen');
    });

    testWidgets('15 รายละเอียดออเดอร์', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.tablet);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');

      unawaited(
        Get.toNamed<void>(
          AppRoutes.orderDetail,
          arguments: {'orderId': ids.kitchenOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'tablet-15-order-detail');
    });

    testWidgets('16 เก็บเงิน', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.tablet);
      await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');

      unawaited(
        Get.toNamed<void>(
          AppRoutes.checkout,
          arguments: {'orderId': ids.openOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'tablet-16-checkout');
    });
  });

  // ---------------------------------------------------------------------
  // เว็บ — ผู้ดูแลระบบ
  // ---------------------------------------------------------------------
  group('เว็บผู้ดูแลระบบ', () {
    /// เปิดเมนูแอดมินด้วย "ชื่อ label" ไม่ใช่เลข index — index ของทุกหน้าขยับ
    /// ทุกครั้งที่มีการเพิ่มเมนูใหม่ใน `HomeBinding.destinationsForRole` แล้ว
    /// ภาพที่ได้ก็จะเป็นคนละหน้าโดยไม่มีอะไรฟ้อง (เคยพลาดมาแล้ว 2 รอบ
    /// ตอนเพิ่มหน้า "กะ" และตอนเพิ่ม "วัตถุดิบ/โปรโมชัน")
    Future<void> openAdminTab(WidgetTester tester, String label) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.desktop);
      await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
      final controller = Get.find<HomeController>();
      final index = controller.destinations.indexWhere(
        (destination) => destination.label == label,
      );
      expect(
        index,
        isNonNegative,
        reason:
            'ไม่พบเมนู "$label" ในเมนูของแอดมิน — '
            'ดู HomeBinding.destinationsForRole ว่า label เปลี่ยนไปหรือเปล่า',
      );
      controller.changeTab(index);
      await ScreenshotHarness.settle(tester);
    }

    testWidgets('17 หน้าเข้าสู่ระบบบนจอกว้าง', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.desktop);
      await ScreenshotHarness.capture(tester, 'web-17-login');
    });

    testWidgets('18 แดชบอร์ด', (tester) async {
      await openAdminTab(tester, 'home_nav_dashboard');
      await ScreenshotHarness.capture(tester, 'web-18-dashboard');
    });

    testWidgets('19 ผังโต๊ะ', (tester) async {
      await openAdminTab(tester, 'home_nav_tables');
      await ScreenshotHarness.capture(tester, 'web-19-tables');
    });

    testWidgets('20 รายการออเดอร์', (tester) async {
      await openAdminTab(tester, 'home_nav_orders');
      await ScreenshotHarness.capture(tester, 'web-20-orders');
    });

    testWidgets('21 จัดการเมนู', (tester) async {
      await openAdminTab(tester, 'home_nav_menu');
      await ScreenshotHarness.capture(tester, 'web-21-menu-management');
    });

    testWidgets('22 ฟอร์มเพิ่ม/แก้ไขเมนู', (tester) async {
      await openAdminTab(tester, 'home_nav_menu');
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'web-22-menu-form');
    });

    testWidgets('23 จัดการพนักงาน', (tester) async {
      await openAdminTab(tester, 'home_nav_staff');
      await ScreenshotHarness.capture(tester, 'web-23-staff');
    });

    testWidgets('24 รายงานยอดขาย', (tester) async {
      await openAdminTab(tester, 'home_nav_reports');
      await ScreenshotHarness.capture(tester, 'web-24-reports');
    });

    testWidgets('25 ตั้งค่าร้าน', (tester) async {
      await openAdminTab(tester, 'home_nav_settings');
      await ScreenshotHarness.capture(tester, 'web-25-settings');
    });
  });

  // ---------------------------------------------------------------------
  // โหมดคอนทราสต์สูง — ถ่ายหน้าเดียวกับโหมดปกติเพื่อให้เทียบกันตรง ๆ ได้
  // ---------------------------------------------------------------------
  group('โหมดคอนทราสต์สูง', () {
    setUp(() => AppColors.contrast = AppContrast.high);
    tearDown(() => AppColors.contrast = AppContrast.standard);

    testWidgets('26 จอครัวโหมดคอนทราสต์สูง', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.tablet);
      await ScreenshotHarness.loginAs(tester, 'kitchen', 'kitchen123');
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(
        tester,
        'tablet-26-kitchen-high-contrast',
      );
    });

    testWidgets('27 ผังโต๊ะโหมดคอนทราสต์สูง', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-27-tables-high-contrast');
    });
  });
}
