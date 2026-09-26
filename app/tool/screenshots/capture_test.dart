// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

@Tags(['screenshots'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/app/routes/app_routes.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/localization/locale_service.dart';
import 'package:payneat_pos/features/customer/presentation/widgets/customer_picker_dialog.dart';
import 'package:payneat_pos/features/home/presentation/controllers/home_controller.dart';
import 'package:payneat_pos/features/payment/presentation/controllers/checkout_controller.dart';
import 'package:payneat_pos/features/self_order/presentation/controllers/self_order_controller.dart';

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
  late ({
    int openOrderId,
    int kitchenOrderId,
    int paidOrderId,
    int takeawayOrderId,
    int customerId,
  })
  ids;

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
    testWidgets('26 จอครัวโหมดคอนทราสต์สูง', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.tablet,
        highContrast: true,
      );
      await ScreenshotHarness.loginAs(tester, 'kitchen', 'kitchen123');
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(
        tester,
        'tablet-26-kitchen-high-contrast',
      );
    });

    testWidgets('27 ผังโต๊ะโหมดคอนทราสต์สูง', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.phone,
        highContrast: true,
      );
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-27-tables-high-contrast');
    });
  });

  // ---------------------------------------------------------------------
  // สั่งกลับบ้าน/เดลิเวอรี่ (ticket 10) — เปิดออเดอร์ไม่ต้องผูกโต๊ะ ได้เลขคิว
  // ---------------------------------------------------------------------
  group('สั่งกลับบ้าน/เดลิเวอรี่', () {
    testWidgets('28 หน้ารับออเดอร์กลับบ้าน (ไม่ผูกโต๊ะ)', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');

      // ไม่ส่ง arguments เลย เหมือนตอนกดปุ่ม "สั่งกลับบ้าน/เดลิเวอรี่" บนหน้าผังโต๊ะจริง
      unawaited(Get.toNamed<void>(AppRoutes.newOrder));
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-28-takeaway-order-taking');
    });

    testWidgets('29 รายละเอียดออเดอร์กลับบ้านพร้อมเลขคิว', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');

      unawaited(
        Get.toNamed<void>(
          AppRoutes.orderDetail,
          arguments: {'orderId': ids.takeawayOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-29-takeaway-order-detail');
    });
  });

  // ---------------------------------------------------------------------
  // ลูกค้า/แต้มสะสม (ticket 09) และ audit log (ticket 08)
  // สองฟีเจอร์นี้เพิ่มหน้าจอมา 4 หน้าแต่ยังไม่เคยมีภาพ golden คุม —
  // ทั้งที่กลไกนี้เคยจับภาพเอกสารค้างได้มาแล้ว
  // ---------------------------------------------------------------------
  group('ลูกค้า/แต้มสะสม และ audit log', () {
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

    testWidgets('30 รายชื่อลูกค้าและแต้มสะสม', (tester) async {
      await openAdminTab(tester, 'home_nav_customers');
      await ScreenshotHarness.capture(tester, 'web-30-customers');
    });

    testWidgets('31 รายละเอียดลูกค้า/ประวัติการซื้อ', (tester) async {
      await openAdminTab(tester, 'home_nav_customers');
      unawaited(
        Get.toNamed<void>(
          AppRoutes.customerDetail,
          arguments: {'customerId': ids.customerId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'web-31-customer-detail');
    });

    testWidgets('32 ประวัติการทำรายการ (audit log)', (tester) async {
      await openAdminTab(tester, 'home_nav_audit_log');
      await ScreenshotHarness.capture(tester, 'web-32-audit-log');
    });

    testWidgets('33 กล่องผูกลูกค้ากับออเดอร์บนมือถือ', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');
      unawaited(
        Get.toNamed<void>(
          AppRoutes.orderDetail,
          arguments: {'orderId': ids.openOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      unawaited(CustomerPickerDialog.show());
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-33-customer-picker');
    });
  });

  // ---------------------------------------------------------------------
  // PromptPay QR จริง (ticket 16) — ยังไม่เคยมีภาพ golden คุมเลย
  // ---------------------------------------------------------------------
  group('PromptPay QR', () {
    testWidgets('34 QR พร้อมเพย์ที่หน้าเก็บเงิน', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');

      unawaited(
        Get.toNamed<void>(
          AppRoutes.checkout,
          arguments: {'orderId': ids.openOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      Get.find<CheckoutController>().selectMethod(PaymentMethod.qr);
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-34-promptpay-qr');
    });
  });

  // ---------------------------------------------------------------------
  // QR สั่งอาหารเอง (ticket 17) — หน้าเดียวในแอปที่ลูกค้าเปิดเองบนมือถือตัวเอง
  // ไม่ผ่าน login จึงต้องคุมภาพไว้แยกจากหน้าพนักงานทุกหน้า
  // ---------------------------------------------------------------------
  group('QR สั่งอาหารเอง', () {
    Future<void> openSelfOrder(WidgetTester tester, String qrToken) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      unawaited(Get.toNamed<void>('/order/$qrToken'));
      await ScreenshotHarness.settle(tester);
    }

    testWidgets('35 หน้าเมนูที่ลูกค้าเห็นหลังสแกน QR', (tester) async {
      await openSelfOrder(tester, 'demo-table-1');
      await ScreenshotHarness.capture(tester, 'phone-35-self-order-menu');
    });

    testWidgets('36 ตะกร้าของลูกค้าก่อนกดส่งครัว', (tester) async {
      await openSelfOrder(tester, 'demo-table-1');
      final controller = Get.find<SelfOrderController>();
      for (final item
          in controller.items
              .where((item) => !item.requiresSelection)
              .take(2)) {
        await controller.addToCart(item);
      }
      await ScreenshotHarness.settle(tester);
      await tester.tap(find.byType(FilledButton).last);
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-36-self-order-cart');
    });

    testWidgets('37 ออเดอร์ปัจจุบันของโต๊ะที่ลูกค้าเปิดดูได้', (tester) async {
      await openSelfOrder(tester, 'demo-table-1');
      await tester.tap(find.byIcon(Icons.receipt_long_rounded));
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(
        tester,
        'phone-37-self-order-current-order',
      );
    });

    testWidgets('38 ลิงก์ QR ที่ใช้ไม่ได้แล้ว (token ผิด/โต๊ะปิด)', (
      tester,
    ) async {
      await openSelfOrder(tester, 'token-mua-mua-123');
      await ScreenshotHarness.capture(tester, 'phone-38-self-order-invalid');
    });

    testWidgets('39 ชีท QR ฝั่งพนักงานที่ผังโต๊ะ', (tester) async {
      await ScreenshotHarness.launchApp(tester, ScreenshotHarness.phone);
      // ผู้จัดการเห็น "ภาพรวม" เป็นแท็บแรก ผังโต๊ะอยู่แท็บที่ 2 (ดู destinationsForRole)
      await ScreenshotHarness.loginAs(tester, 'manager', 'manager123');
      Get.find<HomeController>().changeTab(1);
      await ScreenshotHarness.settle(tester);

      await tester.longPress(find.text('A1').first);
      await ScreenshotHarness.settle(tester);
      await tester.tap(find.text('ดู QR สั่งอาหารเอง'));
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'phone-39-table-qr-sheet');
    });
  });

  // ---------------------------------------------------------------------
  // ภาษาเกาหลี (ticket 18) — ใช้ประกอบหน้า Landing ฉบับเกาหลี
  //
  // ถ่ายเฉพาะหน้าที่หน้า Landing เอาไปใช้จริง ไม่ได้ถ่ายซ้ำทุกหน้า:
  // ผังโต๊ะ / จอครัว / เก็บเงิน / แดชบอร์ด + จอครัวโหมดคอนทราสต์สูง
  // (ภาพคู่เทียบปุ่ม "เริ่มทำ" ตัดมาจากสองภาพจอครัวนี้)
  //
  // ชื่อเมนู ("ผัดกะเพราหมูสับ") ยังเป็นไทย/อังกฤษตามข้อมูลจริงของร้าน —
  // ข้อมูลเมนูในฐานข้อมูลมีแค่สองภาษา ส่วนที่แปลคือ UI ของระบบ
  // ---------------------------------------------------------------------
  group('ภาษาเกาหลี', () {
    late final ({
      int openOrderId,
      int kitchenOrderId,
      int paidOrderId,
      int takeawayOrderId,
      int customerId,
    })
    koIds;

    // สร้างข้อมูลสาธิตใหม่เป็นภาษาเกาหลีทั้งชุด แล้วคืนเป็นภาษาไทยให้กลุ่มอื่น
    // (กลุ่มนี้อยู่ท้ายไฟล์ แต่ไม่พึ่งลำดับการรัน — คืนค่าเองเสมอ)
    setUpAll(() => koIds = ScreenshotHarness.reseedIn('ko'));
    tearDownAll(() => ids = ScreenshotHarness.reseedIn('th'));
    testWidgets('40 ผังโต๊ะภาษาเกาหลี', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.phone,
        locale: LocaleService.korean,
        pixelRatio: 3,
      );
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');
      await ScreenshotHarness.capture(tester, 'ko-40-phone-tables');
    });

    testWidgets('41 จอครัวภาษาเกาหลี', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.tablet,
        locale: LocaleService.korean,
      );
      await ScreenshotHarness.loginAs(tester, 'kitchen', 'kitchen123');
      await ScreenshotHarness.capture(tester, 'ko-41-tablet-kitchen');
    });

    testWidgets('42 จอครัวภาษาเกาหลีโหมดคอนทราสต์สูง', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.tablet,
        highContrast: true,
        locale: LocaleService.korean,
      );
      await ScreenshotHarness.loginAs(tester, 'kitchen', 'kitchen123');
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(
        tester,
        'ko-42-tablet-kitchen-high-contrast',
      );
    });

    testWidgets('43 หน้าเก็บเงินภาษาเกาหลี', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.phone,
        locale: LocaleService.korean,
        pixelRatio: 3,
      );
      await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');

      unawaited(
        Get.toNamed<void>(
          AppRoutes.checkout,
          arguments: {'orderId': koIds.openOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'ko-43-phone-checkout');
    });

    testWidgets('44 แดชบอร์ดผู้ดูแลระบบภาษาเกาหลี', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.desktop,
        locale: LocaleService.korean,
      );
      await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'ko-44-web-dashboard');
    });

    // หน้าที่ "ลูกค้า" เห็นจากมือถือตัวเองหลังสแกน QR — สำหรับร้านเกาหลี นี่คือหน้าที่
    // ตัดสินภาพลักษณ์ของร้านมากกว่าหน้าพนักงานทุกหน้ารวมกัน เพราะลูกค้าเห็นเองกับตา
    testWidgets('46 หน้าเมนูที่ลูกค้าเห็นหลังสแกน QR (เกาหลี)', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.phone,
        locale: LocaleService.korean,
        pixelRatio: 3,
      );
      unawaited(Get.toNamed<void>('/order/demo-table-1'));
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'ko-46-self-order-menu');
    });

    testWidgets('47 ตะกร้าของลูกค้าก่อนกดส่งครัว (เกาหลี)', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.phone,
        locale: LocaleService.korean,
        pixelRatio: 3,
      );
      unawaited(Get.toNamed<void>('/order/demo-table-1'));
      await ScreenshotHarness.settle(tester);
      final controller = Get.find<SelfOrderController>();
      for (final item
          in controller.items
              .where((item) => !item.requiresSelection)
              .take(2)) {
        await controller.addToCart(item);
      }
      await ScreenshotHarness.settle(tester);
      await tester.tap(find.byType(FilledButton).last);
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'ko-47-self-order-cart');
    });

    testWidgets('48 หน้ารับออเดอร์ของพนักงาน (เกาหลี)', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.phone,
        locale: LocaleService.korean,
        pixelRatio: 3,
      );
      await ScreenshotHarness.loginAs(tester, 'waiter1', 'waiter123');
      unawaited(
        Get.toNamed<void>(
          AppRoutes.newOrder,
          arguments: {'tableId': 3, 'tableName': 'A3', 'seats': 4},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'ko-48-order-taking');
    });

    testWidgets('49 ใบเสร็จ (เกาหลี)', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.phone,
        locale: LocaleService.korean,
        pixelRatio: 3,
      );
      await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');
      unawaited(
        Get.toNamed<void>(
          AppRoutes.receipt,
          arguments: {'orderId': koIds.paidOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'ko-49-receipt');
    });

    // GIF สาธิตผู้ช่วย AI เป็นภาษาไทยทั้งใบ (บันทึกจากการเรียก API จริงครั้งเดียว
    // ถ่ายใหม่เป็นเกาหลีต้องมี API key) หน้าเกาหลีจึงต้องมีภาพหน้า AI ภาษาเกาหลี
    // ไว้เป็นภาพหลักก่อน ไม่งั้นทั้งหัวข้อจะดูเหมือนระบบไม่รองรับเกาหลีเลย
    testWidgets('45 หน้าผู้ช่วย AI ภาษาเกาหลี', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.desktop,
        locale: LocaleService.korean,
      );
      await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
      final controller = Get.find<HomeController>();
      final index = controller.destinations.indexWhere(
        (destination) => destination.label == 'home_nav_ai_assistant',
      );
      expect(
        index,
        isNonNegative,
        reason:
            'ไม่พบเมนูผู้ช่วย AI ในเมนูของแอดมิน — '
            'ดู HomeBinding.destinationsForRole ว่า label เปลี่ยนไปหรือเปล่า',
      );
      controller.changeTab(index);
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'ko-45-web-ai-assistant');
    });
  });

  // ---------------------------------------------------------------------
  // ภาษาอังกฤษ — หน้า Landing ฉบับอังกฤษและ README.en.md ใช้ภาพ UI ภาษาไทย
  // มาตลอด (ตรวจด้วย hash แล้วพบว่าเหมือนหน้าไทยทุกไบต์ ต่างแค่ alt text)
  // เป็นปัญหาเดียวกับที่ฉบับเกาหลีเจอ แต่ฝั่งอังกฤษไม่เคยถูกแก้
  // ---------------------------------------------------------------------
  group('ภาษาอังกฤษ', () {
    late final ({
      int openOrderId,
      int kitchenOrderId,
      int paidOrderId,
      int takeawayOrderId,
      int customerId,
    })
    enIds;

    setUpAll(() => enIds = ScreenshotHarness.reseedIn('en'));
    tearDownAll(() => ids = ScreenshotHarness.reseedIn('th'));

    Future<void> phone(WidgetTester tester, String user, String pass) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.phone,
        locale: LocaleService.english,
        pixelRatio: 3,
      );
      await ScreenshotHarness.loginAs(tester, user, pass);
    }

    testWidgets('50 ผังโต๊ะ (อังกฤษ)', (tester) async {
      await phone(tester, 'waiter1', 'waiter123');
      await ScreenshotHarness.capture(tester, 'en-50-phone-tables');
    });

    testWidgets('51 เลือกตัวเลือกเสริม (อังกฤษ)', (tester) async {
      await phone(tester, 'waiter1', 'waiter123');
      unawaited(
        Get.toNamed<void>(
          AppRoutes.newOrder,
          arguments: {'tableId': 3, 'tableName': 'A3', 'seats': 4},
        ),
      );
      await ScreenshotHarness.settle(tester);
      // ชื่อเมนูเป็นภาษาอังกฤษแล้วเพราะ seed ใหม่ด้วย DemoNames.language = 'en'
      await tester.tap(find.text('Basil Pork with Rice').first);
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'en-51-phone-option-sheet');
    });

    testWidgets('52 หน้ารับออเดอร์กลับบ้าน (อังกฤษ)', (tester) async {
      await phone(tester, 'waiter1', 'waiter123');
      unawaited(Get.toNamed<void>(AppRoutes.newOrder));
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'en-52-phone-takeaway-order');
    });

    testWidgets('53 รายละเอียดออเดอร์กลับบ้าน (อังกฤษ)', (tester) async {
      await phone(tester, 'waiter1', 'waiter123');
      unawaited(
        Get.toNamed<void>(
          AppRoutes.orderDetail,
          arguments: {'orderId': enIds.takeawayOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'en-53-phone-takeaway-detail');
    });

    testWidgets('54 หน้าเก็บเงิน (อังกฤษ)', (tester) async {
      await phone(tester, 'cashier', 'cashier123');
      unawaited(
        Get.toNamed<void>(
          AppRoutes.checkout,
          arguments: {'orderId': enIds.openOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'en-54-phone-checkout');
    });

    testWidgets('55 จอครัว (อังกฤษ)', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.tablet,
        locale: LocaleService.english,
      );
      await ScreenshotHarness.loginAs(tester, 'kitchen', 'kitchen123');
      await ScreenshotHarness.capture(tester, 'en-55-tablet-kitchen');
    });

    testWidgets('56 จอครัวโหมดคอนทราสต์สูง (อังกฤษ)', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.tablet,
        highContrast: true,
        locale: LocaleService.english,
      );
      await ScreenshotHarness.loginAs(tester, 'kitchen', 'kitchen123');
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(
        tester,
        'en-56-tablet-kitchen-high-contrast',
      );
    });

    testWidgets('57 เก็บเงินบนแท็บเล็ต (อังกฤษ)', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.tablet,
        locale: LocaleService.english,
      );
      await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');
      unawaited(
        Get.toNamed<void>(
          AppRoutes.checkout,
          arguments: {'orderId': enIds.openOrderId},
        ),
      );
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'en-57-tablet-checkout');
    });

    testWidgets('58 แดชบอร์ดผู้ดูแลระบบ (อังกฤษ)', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.desktop,
        locale: LocaleService.english,
      );
      await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'en-58-web-dashboard');
    });

    // GIF สาธิต AI เป็นคำถามภาษาไทย (ถ่ายใหม่ต้องมี API key) หน้าอังกฤษจึงใช้ภาพนี้
    // เป็นภาพหลักแทน แล้วลิงก์ไปที่ GIF พร้อมบอกตรง ๆ ว่าในคลิปถามเป็นภาษาไทย
    testWidgets('59 หน้าผู้ช่วย AI (อังกฤษ)', (tester) async {
      await ScreenshotHarness.launchApp(
        tester,
        ScreenshotHarness.desktop,
        locale: LocaleService.english,
      );
      await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
      final controller = Get.find<HomeController>();
      final index = controller.destinations.indexWhere(
        (destination) => destination.label == 'home_nav_ai_assistant',
      );
      expect(index, isNonNegative);
      controller.changeTab(index);
      await ScreenshotHarness.settle(tester);
      await ScreenshotHarness.capture(tester, 'en-59-web-ai-assistant');
    });
  });
}
