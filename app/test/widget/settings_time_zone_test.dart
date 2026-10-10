// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/localization/app_translations.dart';
import 'package:payneat_pos/core/localization/locale_service.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/settings/domain/entities/store_settings.dart';
import 'package:payneat_pos/features/settings/domain/repositories/settings_repository.dart';
import 'package:payneat_pos/features/settings/domain/usecases/settings_usecases.dart';
import 'package:payneat_pos/features/settings/presentation/controllers/settings_controller.dart';
import 'package:payneat_pos/features/settings/presentation/widgets/time_zone_field.dart';

/// เขตเวลาของร้านในหน้าตั้งค่า (T03 #94, docs/DECISIONS.md #101): โหลดค่าที่บันทึกไว้ (ค่าเริ่มต้น Asia/Bangkok)
/// ชื่อที่ไม่ใช่รูปแบบ IANA แจ้งเตือนก่อนส่ง และช่องแนะนำเขตเวลาที่ใช้บ่อยระหว่างพิมพ์
class _RecordingSettingsRepository implements SettingsRepository {
  StoreSettings stored = StoreSettings.fallback;
  final timeZones = <String?>[];

  @override
  Future<Result<StoreSettings>> get() async => Result.success(stored);

  @override
  Future<Result<StoreSettings>> update({
    String? storeName,
    double? vatRate,
    double? serviceChargeRate,
    bool? vatIncluded,
    String? storeTaxId,
    String? storeAddress,
    String? storeBranch,
    double? pointsEarnRateBaht,
    double? pointsRedeemValueBaht,
    String? promptPayId,
    String? scaleLabelPrefix,
    int? scaleLabelPluDigits,
    double? lateFeeAnnualRatePercent,
    int? lateFeeGraceDays,
    String? timeZone,
  }) async {
    timeZones.add(timeZone);
    return Result.success(stored);
  }
}

void main() {
  late _RecordingSettingsRepository repository;
  late SettingsController controller;

  Future<void> pumpApp(WidgetTester tester, {Widget? body}) async {
    repository = _RecordingSettingsRepository();
    controller = SettingsController(
      getSettings: GetSettingsUseCase(repository),
      updateSettings: UpdateSettingsUseCase(repository),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocaleService.thai,
        home: Scaffold(body: body),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    controller.onClose();
  }

  testWidgets(
    'โหลดเขตเวลาที่บันทึกไว้ ค่าเริ่มต้น Asia/Bangkok และส่งค่าที่แก้ไปบันทึก',
    (tester) async {
      await pumpApp(tester);
      await controller.load();
      expect(controller.timeZoneController.text, 'Asia/Bangkok');

      controller.timeZoneController.text = ' Asia/Seoul ';
      await controller.save();
      await tester.pump();
      expect(repository.timeZones, ['Asia/Seoul']);
      await settle(tester);
    },
  );

  testWidgets('ชื่อที่ไม่ใช่รูปแบบ IANA แจ้งเตือนและไม่ส่งไปบันทึก', (
    tester,
  ) async {
    await pumpApp(tester);
    await controller.load();
    for (final value in ['Bangkok', '+07:00', '']) {
      controller.timeZoneController.text = value;
      await controller.save();
      await tester.pump();
      expect(
        find.text('settings_time_zone_invalid'.tr),
        findsOneWidget,
        reason: value,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
    expect(repository.timeZones, isEmpty);
    await settle(tester);
  });

  testWidgets('พิมพ์บางส่วนแล้วเลือกจากรายการแนะนำได้', (tester) async {
    final field = TextEditingController();
    addTearDown(field.dispose);
    await pumpApp(
      tester,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TimeZoneField(controller: field),
      ),
    );
    await tester.enterText(find.byType(TextField), 'seo');
    await tester.pumpAndSettle();
    // ค้นเฉพาะในรายการแนะนำ — hint ของช่อง (Asia/Bangkok) ยังอยู่ใน tree แค่ถูกซ่อน
    expect(find.widgetWithText(ListTile, 'Asia/Seoul'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Asia/Bangkok'), findsNothing);

    await tester.tap(find.widgetWithText(ListTile, 'Asia/Seoul'));
    await tester.pumpAndSettle();
    expect(field.text, 'Asia/Seoul');
    controller.onClose();
  });
}
