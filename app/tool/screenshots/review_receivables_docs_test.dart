@Tags(['screenshots'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/app/routes/app_routes.dart';
import 'package:payneat_pos/core/localization/locale_service.dart';
import 'package:payneat_pos/features/customer/domain/usecases/customer_usecases.dart';
import 'package:payneat_pos/features/customer/presentation/widgets/customer_credit_dialog.dart';
import 'package:payneat_pos/features/home/presentation/controllers/home_controller.dart';
import 'package:payneat_pos/features/menu/presentation/controllers/menu_controller.dart';
import 'package:payneat_pos/features/receivable/domain/entities/receivable.dart';
import 'package:payneat_pos/features/receivable/presentation/controllers/customer_statement_controller.dart';
import 'package:payneat_pos/features/receivable/presentation/widgets/credit_note_dialog.dart';
import 'package:payneat_pos/features/receivable/presentation/widgets/email_document_prompt.dart';
import 'package:payneat_pos/features/receivable/presentation/widgets/late_fee_dialog.dart';
import 'package:payneat_pos/features/receivable/presentation/widgets/receivable_document_dialog.dart';

import 'screenshot_harness.dart';

/// ตรวจ UI ของตาชั่งต่อสาย/ดอกเบี้ยผิดนัด/ใบลดหนี้/อีเมลเอกสาร (tickets 21–23) ทุกภาษา × หลายขนาดจอ
/// ถ้ามี RenderFlex ล้น เทสต์จะล้มเอง — ใช้ข้อมูลสาธิตที่มีบิลค้างเกินกำหนดเตรียมไว้แล้ว
///
/// ```
/// flutter test --update-goldens --dart-define=DEMO_MODE=true \
///   tool/screenshots/review_receivables_docs_test.dart
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
      setUpAll(() => ScreenshotHarness.reseedIn(lang));

      Future<void> launch(WidgetTester tester, Size size) =>
          ScreenshotHarness.launchApp(tester, size, locale: cfg.locale);

      Future<CustomerStatementController> openStatement(
        WidgetTester tester,
      ) async {
        unawaited(
          Get.toNamed<void>(
            AppRoutes.customerStatement,
            arguments: {'customerId': _creditCustomerId},
          ),
        );
        await ScreenshotHarness.settle(tester);
        return Get.find<CustomerStatementController>();
      }

      Future<void> closeDialog(WidgetTester tester) async {
        Get.back<void>();
        await ScreenshotHarness.settle(tester);
      }

      for (final (name, size) in [
        ('phone', ScreenshotHarness.phone),
        ('small', _smallPhone),
        ('tablet', ScreenshotHarness.tablet),
        ('desktop', ScreenshotHarness.desktop),
      ]) {
        testWidgets('$lang $name กล่องชั่ง + ตาชั่งอ่านสด', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'cashier', 'cashier123');
          unawaited(Get.toNamed<void>(AppRoutes.newOrder));
          await ScreenshotHarness.settle(tester);
          final browse = Get.find<MenuBrowseController>();
          browse.selectCategory(
            browse.categories.firstWhere((c) => c.displayName == cfg.meat).id,
          );
          await ScreenshotHarness.settle(tester);
          await tester.ensureVisible(find.text(cfg.ribeye).first);
          await tester.tap(find.text(cfg.ribeye).first);
          await ScreenshotHarness.settle(tester, rounds: 30);
          await ScreenshotHarness.capture(tester, 'review2/$lang-$name-scale');
        });

        testWidgets('$lang $name บัญชีลูกหนี้ + ดอกเบี้ย + ใบลดหนี้', (
          tester,
        ) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'manager', 'manager123');
          final c = await openStatement(tester);
          await ScreenshotHarness.capture(
            tester,
            'review2/$lang-$name-statement',
          );

          final preview = await tester.runAsync(c.previewLateFee);
          await ScreenshotHarness.settle(tester);
          if (preview != null) {
            unawaited(LateFeeDialog.show(preview));
            await ScreenshotHarness.settle(tester);
            await ScreenshotHarness.capture(
              tester,
              'review2/$lang-$name-late-preview',
            );
            await closeDialog(tester);
          }

          final invoices = c.statement.value?.invoices ?? const [];
          if (invoices.isNotEmpty) {
            unawaited(CreditNoteDialog.show(invoices));
            await ScreenshotHarness.settle(tester);
            await ScreenshotHarness.capture(
              tester,
              'review2/$lang-$name-credit-note-form',
            );
            await closeDialog(tester);
          }

          final charge = await tester.runAsync(c.issueLateFee);
          await ScreenshotHarness.settle(tester, rounds: 30);
          if (charge != null) {
            await tester.runAsync(
              () => c.emailDocument(
                ReceivableDocumentKind.lateFee,
                charge.id,
                to: 'ap@seoulbbq.example',
              ),
            );
            final withHistory = await tester.runAsync(
              () => c.fetchLateFee(charge.id),
            );
            await ScreenshotHarness.settle(tester, rounds: 30);
            unawaited(
              ReceivableDocumentDialog.showLateFee(
                withHistory ?? charge,
                canVoid: true,
                actions: DocumentActions(
                  email: ({String? to, String? message}) => c.emailDocument(
                    ReceivableDocumentKind.lateFee,
                    charge.id,
                    to: to,
                    message: message,
                  ),
                ),
              ),
            );
            await ScreenshotHarness.settle(tester);
            await ScreenshotHarness.capture(
              tester,
              'review2/$lang-$name-late-doc',
            );
            await closeDialog(tester);

            unawaited(
              EmailDocumentPrompt.show(
                documentNo: charge.chargeNo,
                initialTo: 'ap@seoulbbq.example',
              ),
            );
            await ScreenshotHarness.settle(tester);
            await ScreenshotHarness.capture(
              tester,
              'review2/$lang-$name-email',
            );
            await closeDialog(tester);
          }

          final target = c.statement.value?.invoices.firstOrNull;
          if (target != null) {
            final note = await tester.runAsync(
              () => c.issueCreditNote(
                paymentId: target.paymentId,
                amount: 100,
                reason: 'สินค้าชำรุด 1 แพ็ก',
              ),
            );
            await ScreenshotHarness.settle(tester, rounds: 30);
            if (note != null) {
              unawaited(ReceivableDocumentDialog.showCreditNote(note));
              await ScreenshotHarness.settle(tester);
              await ScreenshotHarness.capture(
                tester,
                'review2/$lang-$name-credit-note-doc',
              );
              await closeDialog(tester);
            }
          }
          await ScreenshotHarness.capture(
            tester,
            'review2/$lang-$name-statement-after',
          );
          // snackbar "ออกเอกสารแล้ว" ยังเลื่อนอยู่ตอนจบเทสต์ → ticker ค้างข้ามไปเทสต์ถัดไป
          // ปล่อยเวลาจำลองให้ snackbar เล่นจนจบเอง (สั่งปิดกลางทางแล้ว GetX assert)
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(seconds: 1));
          }
        });
      }

      for (final (name, size) in [
        ('phone', ScreenshotHarness.phone),
        ('desktop', ScreenshotHarness.desktop),
      ]) {
        testWidgets('$lang $name ตั้งค่าดอกเบี้ย/อีเมล', (tester) async {
          await launch(tester, size);
          await ScreenshotHarness.loginAs(tester, 'admin', 'admin123');
          final home = Get.find<HomeController>();
          home.changeTab(
            home.destinations.indexWhere((d) => d.label == 'home_nav_settings'),
          );
          await ScreenshotHarness.settle(tester);
          final field = find.byKey(const ValueKey('settings-late-fee-rate'));
          if (field.evaluate().isNotEmpty) {
            await tester.ensureVisible(field);
            await ScreenshotHarness.settle(tester);
          }
          await ScreenshotHarness.capture(
            tester,
            'review2/$lang-$name-settings',
          );
        });

        testWidgets('$lang $name ลูกค้าเครดิต + ฟอร์มวงเงิน', (tester) async {
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
            'review2/$lang-$name-customer',
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
              'review2/$lang-$name-credit-dialog',
            );
          }
        });
      }
    });
  }
}
