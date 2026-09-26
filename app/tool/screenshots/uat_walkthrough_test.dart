// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

@Tags(['screenshots'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/app/routes/app_routes.dart';
import 'package:payneat_pos/core/localization/locale_service.dart';
import 'package:payneat_pos/features/home/presentation/controllers/home_controller.dart';
import 'package:payneat_pos/features/kitchen/presentation/controllers/kitchen_controller.dart';

import 'screenshot_harness.dart';

/// ไล่ดูทุกหน้าของทุกบทบาทก่อน UAT แบบไม่มีคนสอน (ลูกค้าลองกดเอง)
///
/// ทุกภาษา × มือถือเล็ก 360 / มือถือ 390 / แท็บเล็ต / เดสก์ท็อป — ล็อกอินทีละบทบาทแล้วเปิดทุกแท็บที่บทบาทนั้น
/// เห็นจริง (อ่านจาก HomeController.destinations ไม่ได้เขียนรายชื่อแท็บเอง) และหน้าที่ต้องกดเข้าไป
/// (รายละเอียดออเดอร์ เก็บเงิน ใบเสร็จ แยกบิล กะ QR สั่งเอง ฟอร์มต่าง ๆ) ถ้ามี RenderFlex ล้น เทสต์ล้มเอง
///
/// ```
/// flutter test --update-goldens --dart-define=DEMO_MODE=true \
///   tool/screenshots/uat_walkthrough_test.dart
/// ```
const _small = Size(360, 740);

const _sizes = {
  'small': _small,
  'phone': ScreenshotHarness.phone,
  'tablet': ScreenshotHarness.tablet,
  'desktop': ScreenshotHarness.desktop,
};

const _langs = {
  'th': LocaleService.thai,
  'en': LocaleService.english,
  'ko': LocaleService.korean,
};

const _roles = {
  'waiter': ('waiter1', 'waiter123'),
  'kitchen': ('kitchen', 'kitchen123'),
  'cashier': ('cashier', 'cashier123'),
  'manager': ('manager', 'manager123'),
  'admin': ('admin', 'admin123'),
};

void main() {
  setUpAll(() async {
    await ScreenshotHarness.loadFonts();
    ScreenshotHarness.freezeClock();
  });
  tearDownAll(() {
    ScreenshotHarness.reseedIn('th');
    ScreenshotHarness.unfreezeClock();
  });

  for (final lang in _langs.keys) {
    group('UAT $lang', () {
      late ({
        int openOrderId,
        int kitchenOrderId,
        int paidOrderId,
        int takeawayOrderId,
        int customerId,
      })
      ids;
      setUpAll(() => ids = ScreenshotHarness.reseedIn(lang));

      Future<void> launch(WidgetTester tester, Size size) =>
          ScreenshotHarness.launchApp(tester, size, locale: _langs[lang]);

      Future<void> shot(WidgetTester tester, String size, String name) =>
          ScreenshotHarness.capture(tester, 'uat/$lang-$size-$name');

      Future<void> open(
        WidgetTester tester,
        String route, [
        Object? args,
      ]) async {
        unawaited(Get.toNamed<void>(route, arguments: args));
        await ScreenshotHarness.settle(tester);
      }

      for (final MapEntry(key: sizeName, value: size) in _sizes.entries) {
        testWidgets('$lang $sizeName หน้าเข้าสู่ระบบ + รหัสผิด', (
          tester,
        ) async {
          await launch(tester, size);
          await shot(tester, sizeName, '00-login');
          final fields = find.byType(TextField);
          if (fields.evaluate().length >= 2) {
            await tester.enterText(fields.at(0), 'cashier');
            await tester.enterText(fields.at(1), 'wrong-password');
            await tester.testTextInput.receiveAction(TextInputAction.done);
            await ScreenshotHarness.settle(tester, rounds: 20);
            await shot(tester, sizeName, '00-login-wrong-password');
          }
        });

        for (final MapEntry(key: role, value: (user, pass)) in _roles.entries) {
          testWidgets('$lang $sizeName $role ทุกแท็บ', (tester) async {
            await launch(tester, size);
            await ScreenshotHarness.loginAs(tester, user, pass);
            final home = Get.find<HomeController>();
            for (var i = 0; i < home.destinations.length; i++) {
              home.changeTab(i);
              await ScreenshotHarness.settle(tester, rounds: 16);
              final label = home.destinations[i].label.replaceFirst(
                'home_nav_',
                '',
              );
              await shot(
                tester,
                sizeName,
                '$role-${i.toString().padLeft(2, '0')}-$label',
              );
            }
          });
        }
      }

      // สิ่งที่เพิ่มตาม DECISIONS #64 — แถบเลิกทำในจอครัว, ปฏิทินตามภาษา, ชื่อพนักงานตามภาษา
      testWidgets('$lang small ครัวเลิกทำ', (tester) async {
        await launch(tester, _small);
        await ScreenshotHarness.loginAs(tester, 'kitchen', 'kitchen123');
        final kitchen = Get.find<KitchenController>();
        await tester.runAsync(() => kitchen.advance(kitchen.pending.first));
        await ScreenshotHarness.settle(tester);
        await shot(tester, 'small', 'x63-01-kitchen-undo');
        await tester.runAsync(kitchen.undoLast);
        await ScreenshotHarness.settle(tester);
      });

      testWidgets('$lang small ปฏิทิน + พนักงาน', (tester) async {
        await launch(tester, _small);
        await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
        await open(tester, AppRoutes.promotionForm);
        final from = find.byIcon(Icons.calendar_today_rounded).first;
        await tester.ensureVisible(from);
        await ScreenshotHarness.settle(tester);
        await tester.tap(from);
        await ScreenshotHarness.settle(tester);
        await shot(tester, 'small', 'x63-02-date-picker');
        Get.back<void>();
        await ScreenshotHarness.settle(tester);
        Get.back<void>();
        await ScreenshotHarness.settle(tester);

        final home = Get.find<HomeController>();
        home.changeTab(
          home.destinations.indexWhere((d) => d.label == 'home_nav_staff'),
        );
        await ScreenshotHarness.settle(tester);
        await shot(tester, 'small', 'x63-03-staff');
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
      });

      for (final MapEntry(key: sizeName, value: size) in {
        'small': _small,
        'phone': ScreenshotHarness.phone,
        'tablet': ScreenshotHarness.tablet,
      }.entries) {
        testWidgets('$lang $sizeName เส้นทางแคชเชียร์', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');
          await open(tester, AppRoutes.orderDetail, {
            'orderId': ids.kitchenOrderId,
          });
          await shot(tester, sizeName, 'flow-01-order-detail');
          Get.back<void>();
          await ScreenshotHarness.settle(tester);
          await open(tester, AppRoutes.checkout, {'orderId': ids.openOrderId});
          await shot(tester, sizeName, 'flow-02-checkout');
          Get.back<void>();
          await ScreenshotHarness.settle(tester);
          await open(tester, AppRoutes.splitBill, {'orderId': ids.openOrderId});
          await shot(tester, sizeName, 'flow-03-split-bill');
          Get.back<void>();
          await ScreenshotHarness.settle(tester);
          await open(tester, AppRoutes.receipt, {'orderId': ids.paidOrderId});
          await shot(tester, sizeName, 'flow-04-receipt');
          Get.back<void>();
          await ScreenshotHarness.settle(tester);
          await open(tester, AppRoutes.newOrder, {
            'tableId': 3,
            'tableName': 'A3',
            'seats': 4,
          });
          await shot(tester, sizeName, 'flow-05-new-order');
        });

        testWidgets('$lang $sizeName ลูกค้าสแกน QR', (tester) async {
          await launch(tester, size);
          await open(tester, '/order/demo-table-1');
          await shot(tester, sizeName, 'qr-01-menu');
          final receipt = find.byIcon(Icons.receipt_long_rounded);
          if (receipt.evaluate().isNotEmpty) {
            await tester.tap(receipt.first);
            await ScreenshotHarness.settle(tester);
            await shot(tester, sizeName, 'qr-02-current-order');
          }
        });

        testWidgets('$lang $sizeName ลิงก์ QR เสีย', (tester) async {
          await launch(tester, size);
          await open(tester, '/order/token-that-does-not-exist');
          await shot(tester, sizeName, 'qr-03-invalid');
        });

        testWidgets('$lang $sizeName ฟอร์มผู้จัดการ', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
          // ฟอร์มโต๊ะ/พนักงานเป็นกล่อง dialog ไม่ใช่ route (ค่าคงที่ tableForm/staffForm ไม่ได้ลงทะเบียน
          // ใน app_pages) — เปิดผ่าน toNamed แล้ว Get.back จะไปปิดหน้าแรกแทน timer ของหน้านั้นเลยค้าง
          for (final (name, route) in [
            ('form-03-promotion', AppRoutes.promotionForm),
            ('form-04-ingredient', AppRoutes.ingredientForm),
            ('form-05-menu', AppRoutes.menuForm),
          ]) {
            await open(tester, route);
            await shot(tester, sizeName, name);
            Get.back<void>();
            await ScreenshotHarness.settle(tester);
          }
          await open(tester, AppRoutes.shift);
          await shot(tester, sizeName, 'form-06-shift');
          // timer ของหน้า shift/snackbar ยังค้างตอนจบเทสต์ → ปล่อยเวลาจำลองให้จบเอง (แบบเดียวกับ review2)
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(seconds: 1));
          }
        });
      }
    });
  }
}
