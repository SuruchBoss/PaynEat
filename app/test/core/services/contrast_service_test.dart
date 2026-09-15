import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/app/theme/app_colors.dart';
import 'package:payneat_pos/app/theme/app_theme.dart';
import 'package:payneat_pos/core/services/contrast_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.put<StorageService>(StorageService.memory(), permanent: true);
    AppColors.contrast = AppContrast.standard;
  });

  tearDown(() {
    AppColors.contrast = AppContrast.standard;
    Get.reset();
  });

  group('ContrastService', () {
    // ภาพหน้าจอของโหมดคอนทราสต์สูงถ่ายโดยตั้ง AppColors.contrast ตรง ๆ
    // ซึ่งข้ามเส้นทางจริงที่ผู้ใช้กดไปทั้งหมด เทสต์ชุดนี้จึงคุมเส้นทางนั้นแทน

    testWidgets('change(true) เปลี่ยนพาเลตต์และบันทึกลงเครื่อง', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox.shrink()));

      expect(ContrastService.isHigh, isFalse);
      await ContrastService.change(true);
      await tester
          .pump(); // ปล่อยให้ post-frame callback ของ forceAppUpdate ทำงาน

      expect(ContrastService.isHigh, isTrue);
      expect(AppColors.contrast, AppContrast.high);
      expect(Get.find<StorageService>().contrast, 'high');
    });

    testWidgets('change(false) กลับมาโหมดปกติและบันทึกทับค่าเดิม', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox.shrink()));

      await ContrastService.change(true);
      await tester.pump();
      await ContrastService.change(false);
      await tester.pump();

      expect(ContrastService.isHigh, isFalse);
      expect(Get.find<StorageService>().contrast, 'standard');
    });

    test('restore อ่านค่าที่เคยเลือกไว้กลับมาตอนเปิดแอปใหม่', () async {
      await Get.find<StorageService>().saveContrast('high');
      // จำลองการเปิดแอปใหม่ — พาเลตต์เริ่มจากค่าเริ่มต้นเสมอ
      AppColors.contrast = AppContrast.standard;

      ContrastService.restore();

      expect(AppColors.contrast, AppContrast.high);
    });

    test('restore เมื่อไม่เคยตั้งค่าไว้ → คงโหมดปกติ', () {
      ContrastService.restore();
      expect(AppColors.contrast, AppContrast.standard);
    });

    test(
      'restore ไม่พังถ้ายังไม่มี StorageService (เช่นตอนเทสต์ระดับหน่วย)',
      () {
        Get.reset();
        expect(ContrastService.restore, returnsNormally);
        expect(AppColors.contrast, AppContrast.standard);
      },
    );

    test('ธีมต้องสร้างสีใหม่ทุกครั้งที่อ่าน ไม่ใช่คำนวณครั้งเดียวแล้วค้าง', () {
      // นี่คือบั๊กที่เจอจริงตอนทำฟีเจอร์นี้ — AppTheme._textTheme เคยเป็น
      // `static const` พอถอด const ออกมันกลายเป็น field ที่คำนวณครั้งเดียว
      // ตอนคลาสถูกโหลด สีตัวหนังสือของธีมจึงค้างเป็นของโหมดแรกที่เปิด
      AppColors.contrast = AppContrast.standard;
      final standard = AppTheme.light.textTheme.bodyMedium?.color;

      AppColors.contrast = AppContrast.high;
      final high = AppTheme.light.textTheme.bodyMedium?.color;

      expect(standard, AppColors.textPrimaryFor(AppContrast.standard));
      expect(high, AppColors.textPrimaryFor(AppContrast.high));
      expect(high, isNot(standard));
    });
  });
}
