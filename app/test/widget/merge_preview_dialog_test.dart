// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/utils/formatters.dart';
import 'package:payneat_pos/features/order/data/models/merge_preview_model.dart';
import 'package:payneat_pos/features/order/presentation/widgets/merge_preview_dialog.dart';

/// หน้ายืนยันรวมบิล (T09 #96): ต้องเห็นยอดจ่ายแล้วและส่วนลดของทั้งสองฝั่งก่อนกด ส่วนลดที่จะหายต้องบอกบนจอนี้
/// และยอดหลังรวมที่ต่ำกว่าเงินที่รับไว้กดรวมไม่ได้
Map<String, dynamic> _json({double discountLost = 0, double refund = 0}) => {
  'target': {
    'code': 'B002',
    'total': 94.16,
    'paid': 0,
    'discount': 0,
    'promotionDiscount': 0,
    'promotionName': null,
  },
  'source': {
    'code': 'A001',
    'total': 88.28,
    'paid': 50,
    'discount': 10,
    'promotionDiscount': 0,
    'promotionName': null,
  },
  'merged': {
    'total': 182.44,
    'paid': 50,
    'remaining': 132.44,
    'refundRequired': refund,
    'discount': 10,
    'promotionDiscount': 0,
    'promotionName': null,
  },
  'discountLost': discountLost,
};

void main() {
  Future<Future<bool>> open(
    WidgetTester tester,
    Map<String, dynamic> json,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: Text('order-detail'))),
    );
    addTearDown(Get.reset);
    final result = MergePreviewDialog.show(
      MergePreviewModel.fromJson(json),
      sourceLabel: 'โต๊ะ 1',
      targetLabel: 'โต๊ะ 2',
    );
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets(
    'แสดงยอดจ่ายแล้วและส่วนลดของทั้งสองฝั่งกับยอดหลังรวม กดรวมแล้วได้ true',
    (tester) async {
      final result = await open(tester, _json());

      expect(find.textContaining('#A001'), findsOneWidget);
      expect(find.textContaining('#B002'), findsOneWidget);
      expect(find.text(Formatters.baht(50)), findsNWidgets(2));
      expect(find.text(Formatters.baht(10)), findsNWidgets(2));
      expect(find.text(Formatters.baht(182.44)), findsOneWidget);
      expect(find.text(Formatters.baht(132.44)), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    },
  );

  testWidgets('ส่วนลดรวมจะลดลง → บอกยอดที่หายบนจอก่อนยืนยัน', (tester) async {
    final result = await open(tester, _json(discountLost: 8.5));

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(
      find.text(
        'order_merge_preview_discount_lost'.trParams({
          'amount': Formatters.baht(8.5),
        }),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('common_cancel'.tr));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets(
    'ยอดหลังรวมต่ำกว่าเงินที่รับไว้ → บอกยอดที่ต้องคืนและกดรวมไม่ได้',
    (tester) async {
      await open(tester, _json(refund: 5));

      expect(
        find.text(
          'order_merge_preview_refund_required'.trParams({
            'amount': Formatters.baht(5),
          }),
        ),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    },
  );
}
