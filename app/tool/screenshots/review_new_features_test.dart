// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

@Tags(['screenshots'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/app/routes/app_routes.dart';
import 'package:payneat_pos/core/demo/demo_store.dart';
import 'package:payneat_pos/core/localization/locale_service.dart';
import 'package:payneat_pos/features/customer/domain/usecases/customer_usecases.dart';
import 'package:payneat_pos/features/customer/presentation/widgets/customer_credit_dialog.dart';
import 'package:payneat_pos/features/home/presentation/controllers/home_controller.dart';
import 'package:payneat_pos/features/menu/presentation/controllers/menu_controller.dart';
import 'package:payneat_pos/features/menu/presentation/controllers/menu_management_controller.dart';
import 'package:payneat_pos/features/order/presentation/controllers/cart_controller.dart';
import 'package:payneat_pos/features/payment/presentation/controllers/checkout_controller.dart';
import 'package:payneat_pos/features/receivable/presentation/controllers/customer_statement_controller.dart';
import 'package:payneat_pos/features/receivable/presentation/widgets/receive_payment_dialog.dart';

import 'screenshot_harness.dart';

/// ตรวจ UI ของฟีเจอร์ขายตามน้ำหนัก / สแกนบาร์โค้ด / ขายเชื่อ (tickets 18–20)
/// ทุกภาษา × หลายขนาดจอ — ถ้ามี RenderFlex ล้น เทสต์จะล้มเอง
///
/// ```
/// flutter test --update-goldens --dart-define=DEMO_MODE=true \
///   tool/screenshots/review_new_features_test.dart
/// ```
const _creditCustomerId = 900;
const _smallPhone = Size(360, 740);

const _langs = {
  'th': (
    locale: LocaleService.thai,
    meat: 'เนื้อสด & ของกลับบ้าน',
    ribeye: 'เนื้อวัวริบอาย',
  ),
  'en': (
    locale: LocaleService.english,
    meat: 'Fresh Meat & Take-home',
    ribeye: 'Beef Ribeye',
  ),
  'ko': (locale: LocaleService.korean, meat: '정육 · 포장', ribeye: '소고기 꽃등심'),
};

/// บิลขายเชื่อ 2 ใบ (ใบหนึ่งเก่าเกินเครดิตเทอม) + บิลเปิดค้างของลูกค้าเครดิตไว้ถ่ายหน้าเก็บเงิน
({int openCreditOrderId, int paidWeighedOrderId}) _seedCredit() {
  final store = DemoStore.instance;
  Map<String, dynamic> weighed(int menuId, int grams) => {
    'menuItemId': menuId,
    'quantity': 1,
    'weightGrams': grams,
  };

  final first = store.createOrder(
    type: 'takeaway',
    customerId: _creditCustomerId,
    guestCount: 1,
    waiterId: 6,
    items: [
      weighed(26, 2485),
      weighed(25, 3120),
      {'menuItemId': 28, 'quantity': 6},
    ],
  );
  store.pay(
    orderId: first['id'] as int,
    method: 'credit',
    amount: (store.findOrder(first['id'] as int)['total'] as num).toDouble(),
    cashierId: 6,
  );
  final old = store.payments.lastWhere((p) => p['orderId'] == first['id']);
  old['createdAt'] = DateTime.utc(2026, 7, 28, 5).toIso8601String();
  old['dueDate'] = '2026-08-27';

  final second = store.createOrder(
    type: 'takeaway',
    customerId: _creditCustomerId,
    guestCount: 1,
    waiterId: 6,
    items: [
      weighed(27, 4250),
      {'menuItemId': 29, 'quantity': 10},
    ],
  );
  store.pay(
    orderId: second['id'] as int,
    method: 'credit',
    amount: (store.findOrder(second['id'] as int)['total'] as num).toDouble(),
    cashierId: 6,
  );

  final open = store.createOrder(
    type: 'takeaway',
    customerId: _creditCustomerId,
    guestCount: 1,
    waiterId: 6,
    items: [weighed(26, 485), weighed(26, 512), weighed(25, 1030)],
  );

  final walkIn = store.createOrder(
    type: 'takeaway',
    guestCount: 1,
    waiterId: 6,
    items: [
      weighed(26, 485),
      {'menuItemId': 28, 'quantity': 1},
    ],
  );
  final total = (store.findOrder(walkIn['id'] as int)['total'] as num)
      .toDouble();
  store.pay(
    orderId: walkIn['id'] as int,
    method: 'cash',
    amount: total,
    received: (total / 100).ceil() * 100.0,
    cashierId: 6,
  );
  return (
    openCreditOrderId: open['id'] as int,
    paidWeighedOrderId: walkIn['id'] as int,
  );
}

void main() {
  setUpAll(() async {
    await ScreenshotHarness.loadFonts();
    ScreenshotHarness.freezeClock();
  });
  tearDownAll(() {
    ScreenshotHarness.reseedIn('th');
    ScreenshotHarness.unfreezeClock();
  });

  for (final entry in _langs.entries) {
    final lang = entry.key;
    final cfg = entry.value;
    group('ตรวจ $lang', () {
      late ({int openCreditOrderId, int paidWeighedOrderId}) credit;
      setUpAll(() {
        ScreenshotHarness.reseedIn(lang);
        credit = _seedCredit();
      });

      Future<void> launch(WidgetTester tester, Size size) =>
          ScreenshotHarness.launchApp(tester, size, locale: cfg.locale);

      Future<void> openTab(WidgetTester tester, String label) async {
        final controller = Get.find<HomeController>();
        final index = controller.destinations.indexWhere(
          (d) => d.label == label,
        );
        expect(index, isNonNegative, reason: 'ไม่พบเมนู $label');
        controller.changeTab(index);
        await ScreenshotHarness.settle(tester);
      }

      Future<void> openMeatOrder(WidgetTester tester) async {
        unawaited(Get.toNamed<void>(AppRoutes.newOrder, arguments: null));
        await ScreenshotHarness.settle(tester);
        final meat = Get.find<MenuBrowseController>().categories.firstWhere(
          (c) => c.displayName == cfg.meat,
        );
        Get.find<MenuBrowseController>().selectCategory(meat.id);
        await ScreenshotHarness.settle(tester);
      }

      for (final (name, size) in [
        ('phone', ScreenshotHarness.phone),
        ('small', _smallPhone),
        ('tablet', ScreenshotHarness.tablet),
      ]) {
        testWidgets('$lang $name สั่งเนื้อ + ช่องสแกน', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');
          await openMeatOrder(tester);
          await ScreenshotHarness.capture(tester, 'review/$lang-$name-order');
        });

        testWidgets('$lang $name กล่องชั่งน้ำหนัก', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');
          await openMeatOrder(tester);
          await tester.ensureVisible(find.text(cfg.ribeye).first);
          await ScreenshotHarness.settle(tester);
          await tester.tap(find.text(cfg.ribeye).first);
          await ScreenshotHarness.settle(tester);
          final field = find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(TextField),
          );
          if (field.evaluate().isNotEmpty) {
            await tester.enterText(field.first, '0.485');
            await ScreenshotHarness.settle(tester);
          }
          await ScreenshotHarness.capture(tester, 'review/$lang-$name-weight');
        });

        testWidgets('$lang $name ตะกร้ามีถุงชั่ง', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');
          await openMeatOrder(tester);
          final items = Get.find<MenuBrowseController>().items;
          final cart = Get.find<CartController>();
          cart.addWeighedItem(items.firstWhere((i) => i.id == 26), 485);
          cart.addWeighedItem(items.firstWhere((i) => i.id == 26), 1012);
          cart.addWeighedItem(items.firstWhere((i) => i.id == 25), 730);
          cart.addItem(items.firstWhere((i) => i.id == 28), quantity: 2);
          await ScreenshotHarness.settle(tester);
          if (size != ScreenshotHarness.tablet) {
            await tester.tap(find.byIcon(Icons.shopping_basket_outlined).first);
            await ScreenshotHarness.settle(tester);
          }
          await ScreenshotHarness.capture(tester, 'review/$lang-$name-cart');
        });

        testWidgets('$lang $name เก็บเงินแบบขายเชื่อ', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');
          unawaited(
            Get.toNamed<void>(
              AppRoutes.checkout,
              arguments: {'orderId': credit.openCreditOrderId},
            ),
          );
          await ScreenshotHarness.settle(tester);
          Get.find<CheckoutController>().selectMethod('credit');
          await ScreenshotHarness.settle(tester);
          await ScreenshotHarness.capture(
            tester,
            'review/$lang-$name-checkout-credit',
          );
        });

        testWidgets('$lang $name ใบเสร็จมีบรรทัดชั่ง', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');
          unawaited(
            Get.toNamed<void>(
              AppRoutes.receipt,
              arguments: {'orderId': credit.paidWeighedOrderId},
            ),
          );
          await ScreenshotHarness.settle(tester);
          await ScreenshotHarness.capture(tester, 'review/$lang-$name-receipt');
        });

        testWidgets('$lang $name ลูกหนี้', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');
          await openTab(tester, 'home_nav_receivables');
          await ScreenshotHarness.capture(
            tester,
            'review/$lang-$name-receivables',
          );
        });

        testWidgets('$lang $name บัญชีลูกหนี้รายคน + รับชำระ', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');
          unawaited(
            Get.toNamed<void>(
              AppRoutes.customerStatement,
              arguments: {'customerId': _creditCustomerId},
            ),
          );
          await ScreenshotHarness.settle(tester);
          await ScreenshotHarness.capture(
            tester,
            'review/$lang-$name-statement',
          );
          final statement =
              Get.find<CustomerStatementController>().statement.value;
          if (statement != null) {
            unawaited(ReceivePaymentDialog.show(statement));
            await ScreenshotHarness.settle(tester);
            await ScreenshotHarness.capture(
              tester,
              'review/$lang-$name-receive',
            );
          }
        });
      }

      for (final (name, size) in [
        ('phone', ScreenshotHarness.phone),
        ('desktop', ScreenshotHarness.desktop),
      ]) {
        testWidgets('$lang $name ลูกค้าเครดิต + ตั้งวงเงิน', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
          unawaited(
            Get.toNamed<void>(
              AppRoutes.customerDetail,
              arguments: {'customerId': _creditCustomerId},
            ),
          );
          await ScreenshotHarness.settle(tester);
          await ScreenshotHarness.capture(
            tester,
            'review/$lang-$name-customer',
          );
          final customer = await tester.runAsync(
            () => Get.find<GetCustomerUseCase>()(_creditCustomerId),
          );
          final data = customer?.dataOrNull;
          if (data != null) {
            unawaited(CustomerCreditDialog.show(data));
            await ScreenshotHarness.settle(tester);
            await ScreenshotHarness.capture(
              tester,
              'review/$lang-$name-credit-dialog',
            );
          }
        });

        testWidgets('$lang $name ฟอร์มเมนูขายตามน้ำหนัก', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
          await openTab(tester, 'home_nav_menu');
          final item = Get.find<MenuManagementController>().items.firstWhere(
            (i) => i.id == 26,
          );
          unawaited(
            Get.toNamed<void>(AppRoutes.menuForm, arguments: {'item': item}),
          );
          await ScreenshotHarness.settle(tester);
          await ScreenshotHarness.capture(
            tester,
            'review/$lang-$name-menu-form',
          );
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -700),
          );
          await ScreenshotHarness.settle(tester);
          await ScreenshotHarness.capture(
            tester,
            'review/$lang-$name-menu-form-2',
          );
        });

        testWidgets('$lang $name ลูกหนี้ (แอดมิน)', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
          await openTab(tester, 'home_nav_receivables');
          await ScreenshotHarness.capture(
            tester,
            'review/$lang-$name-admin-receivables',
          );
        });

        testWidgets('$lang $name รายงาน', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
          await openTab(tester, 'home_nav_reports');
          await ScreenshotHarness.capture(tester, 'review/$lang-$name-reports');
        });

        testWidgets('$lang $name ตั้งค่า (ฉลากตาชั่ง)', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
          await openTab(tester, 'home_nav_settings');
          final scale = find.textContaining(
            RegExp('EAN|ตาชั่ง|scale|저울', caseSensitive: false),
          );
          if (scale.evaluate().isNotEmpty) {
            await tester.ensureVisible(scale.first);
            await ScreenshotHarness.settle(tester);
          }
          await ScreenshotHarness.capture(
            tester,
            'review/$lang-$name-settings',
          );
        });
      }
    });
  }
}
