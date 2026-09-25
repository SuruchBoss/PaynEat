import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/localization/app_translations.dart';
import 'package:payneat_pos/core/localization/locale_service.dart';
import 'package:payneat_pos/core/widgets/language_menu_button.dart';
import 'package:payneat_pos/features/report/presentation/widgets/stat_card.dart';
import 'package:payneat_pos/features/table/domain/entities/dining_table.dart';
import 'package:payneat_pos/features/table/presentation/widgets/table_card.dart';

/// จุดที่เจอตอนตรวจก่อน UAT แบบไม่มีคนสอน (docs/DECISIONS.md #62) — ถ้าถอยกลับ เทสต์พวกนี้แดง
void main() {
  tearDown(Get.reset);

  Widget app(Widget child, {Locale locale = LocaleService.thai}) =>
      GetMaterialApp(
        translations: AppTranslations(),
        locale: locale,
        home: Scaffold(body: child),
      );

  group('LanguageMenuButton', () {
    for (final (locale, label) in [
      (LocaleService.thai, 'ไทย'),
      (LocaleService.english, 'English'),
      (LocaleService.korean, '한국어'),
    ]) {
      testWidgets(
        '${locale.languageCode}: ปุ่มบอกภาษาปัจจุบันด้วยชื่อภาษานั้นเอง',
        (tester) async {
          await tester.pumpWidget(
            app(const Center(child: LanguageMenuButton()), locale: locale),
          );
          expect(find.text(label), findsOneWidget);
        },
      );
    }

    testWidgets(
      'เปิดเมนูแล้วเห็นครบ 3 ภาษา — อ่านภาษาปัจจุบันไม่ออกก็หาภาษาตัวเองเจอ',
      (tester) async {
        await tester.pumpWidget(
          app(
            const Center(child: LanguageMenuButton()),
            locale: LocaleService.korean,
          ),
        );
        await tester.tap(find.byKey(const ValueKey('language-menu')));
        await tester.pumpAndSettle();
        expect(find.text('ไทย'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(
          find.text('한국어'),
          findsNWidgets(2),
          reason: 'ปุ่ม + รายการในเมนู',
        );
      },
    );
  });

  group('StatGrid', () {
    // เดิมใช้ GridView อัตราส่วนตายตัว คำบรรยายยาว (ไทย/เกาหลี) ล้นกล่องบนจอ 360 ทุกภาษา
    for (final width in [320.0, 360.0, 600.0]) {
      testWidgets(
        'กว้าง ${width.toInt()} + คำบรรยายยาว → ไม่ล้น การ์ดแถวเดียวกันสูงเท่ากัน',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            app(
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: StatGrid(
                  columns: 2,
                  children: [
                    for (var i = 0; i < 3; i++)
                      StatCard(
                        key: ValueKey('stat-$i'),
                        label: 'ยอดขายวันนี้รวมทุกช่องทาง',
                        value: '฿128,450.00',
                        icon: Icons.payments_rounded,
                        color: Colors.teal,
                        caption: i == 0
                            ? '어제 같은 시간 대비 +12% · 결제 완료 주문 기준 · 환불 제외'
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          final a = tester.getSize(find.byKey(const ValueKey('stat-0')));
          final b = tester.getSize(find.byKey(const ValueKey('stat-1')));
          expect(a.height, b.height);
        },
      );
    }
  });

  group('TableCard', () {
    const table = DiningTable(
      id: 7,
      name: 'A7',
      zone: 'โซนใน',
      seats: 4,
      status: TableStatus.available,
    );

    testWidgets(
      'มีปุ่ม ⋯ ให้เห็น (ไม่ต้องรู้ว่าต้องกดค้าง) และกดแล้วเปิดเมนูเดียวกัน',
      (tester) async {
        var opened = 0;
        await tester.pumpWidget(
          app(
            SizedBox(
              width: 160,
              height: 140,
              child: TableCard(
                table: table,
                onTap: () {},
                onLongPress: () => opened++,
              ),
            ),
          ),
        );
        final button = find.byKey(const ValueKey('table-actions-7'));
        expect(button, findsOneWidget);
        await tester.tap(button);
        expect(opened, 1);
        await tester.longPress(find.text('A7'));
        expect(opened, 2);
      },
    );

    testWidgets('ไม่มีเมนู (onLongPress = null) → ไม่โชว์ปุ่ม ⋯', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 160,
            height: 140,
            child: TableCard(table: table, onTap: () {}),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('table-actions-7')), findsNothing);
    });
  });
}
