// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/core/utils/formatters.dart';
import 'package:payneat_pos/features/payment/domain/entities/payment.dart';
import 'package:payneat_pos/features/payment/presentation/widgets/refund_dialog.dart';

/// กล่องคืนเงินของบิลที่ใช้แต้มจ่าย (T11 #101, docs/DECISIONS.md #77 D7): ต้องเห็นเงินกับแต้มที่จะคืนก่อนกดยืนยัน
/// แก้ยอดแล้วต้องดูตัวอย่างใหม่ และยอดที่ระบบปฏิเสธแสดงเหตุผลในกล่อง ไม่คืนเงิน
void main() {
  Future<Future<RefundResult?>> open(
    WidgetTester tester,
    Future<Result<RefundPreview>> Function(double amount) preview,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: Text('receipt'))),
    );
    addTearDown(Get.reset);
    final result = RefundDialog.show(maxAmount: 100.05, preview: preview);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'คืนอาหาร');
    return result;
  }

  Future<Result<RefundPreview>> fifty(double amount) async => Result.success(
    RefundPreview(
      amount: amount,
      cashAmount: 31,
      pointsReturned: 19,
      pointsValue: 19,
    ),
  );

  testWidgets('กดครั้งแรกแสดงเงินกับแต้มที่จะคืน กดอีกครั้งจึงคืน', (
    tester,
  ) async {
    final asked = <double>[];
    final result = await open(tester, (amount) {
      asked.add(amount);
      return fifty(amount);
    });
    await tester.enterText(find.byType(TextField).first, '50');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(asked, [50]);
    expect(
      find.text(
        'payment_refund_split_preview'.trParams({
          'cash': Formatters.baht(31),
          'points': '19',
          'value': Formatters.baht(19),
        }),
      ),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsOneWidget, reason: 'ยังไม่คืน');

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    final done = await result;
    expect(done?.amount, 50);
    expect(done?.reason, 'คืนอาหาร');
    expect(asked, [50], reason: 'ยืนยันรอบสองไม่ต้องถามซ้ำ');
  });

  testWidgets('แก้ยอดหลังเห็นตัวอย่าง → ตัวอย่างเดิมหาย ต้องดูใหม่ก่อนคืน', (
    tester,
  ) async {
    final asked = <double>[];
    await open(tester, (amount) {
      asked.add(amount);
      return fifty(amount);
    });
    await tester.enterText(find.byType(TextField).first, '50');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('payment_refund_split_confirm_hint'.tr), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '40');
    await tester.pump();
    expect(find.text('payment_refund_split_confirm_hint'.tr), findsNothing);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(asked, [50, 40]);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('ระบบปฏิเสธยอดนี้ → แสดงเหตุผลในกล่อง ไม่ปิดกล่อง', (
    tester,
  ) async {
    await open(
      tester,
      (_) async =>
          const Result.failure(ValidationFailure('คืนเป็นแต้มเต็มแต้ม')),
    );
    await tester.enterText(find.byType(TextField).first, '0.3');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('คืนเป็นแต้มเต็มแต้ม'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('payment_refund_split_confirm_hint'.tr), findsNothing);
  });
}
