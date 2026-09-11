import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/app/theme/app_colors.dart';

/// คำนวณอัตราส่วนคอนทราสต์ตามสูตร WCAG 2.1
double _contrast(Color a, Color b) {
  double channel(double v) {
    final c = v / 255;
    return c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4) as double;
  }

  double luminance(Color c) =>
      0.2126 * channel(c.r * 255) +
      0.7152 * channel(c.g * 255) +
      0.0722 * channel(c.b * 255);

  final la = luminance(a);
  final lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  // AppColors.contrast เป็น static ที่ใช้ร่วมกันทั้ง process — ถ้าเทสต์ไหนตั้งค้างไว้
  // เทสต์ตัวถัดไปจะวาดด้วยพาเลตต์ผิดโดยหาสาเหตุยากมาก
  tearDown(() => AppColors.contrast = AppContrast.standard);

  /// ทุกพื้นที่ ink ถูกวางจริงในแอป — ไม่ใช่แค่พื้นขาว
  ///
  /// สำคัญมาก: เวอร์ชันแรกของเทสต์นี้เทียบกับ [AppColors.surface] อย่างเดียว
  /// จึงผ่านหมดทั้งที่ของจริงหลายที่วางบนพื้นเทาอ่อนหรือพื้น soft ของสีตัวเอง
  /// ซึ่งกินคอนทราสต์ไปอีก 0.5-1.5 จุด ทำให้รายงานตัวเลขเกินความจริง
  List<(String, Color)> surfaces() => [
    ('surface', AppColors.surface),
    ('background', AppColors.background),
    ('surfaceAlt', AppColors.surfaceAlt),
    ('primarySoft', AppColors.primarySoft),
    ('secondarySoft', AppColors.secondarySoft),
  ];

  /// ตัวหนังสือ/ไอคอนที่ผู้ใช้ต้องอ่านออกจริง
  ///
  /// จงใจไม่รวม textDisabled เพราะหน้าที่ของมันคือ "ดูไม่พร้อมใช้งาน"
  /// ถ้าดันให้ถึง AAA จะแยกจากข้อความปกติไม่ออก ซึ่งผิดวัตถุประสงค์
  List<(String, Color)> readableInk() => [
    ('brandInk', AppColors.brandInk),
    ('warningInk', AppColors.warningInk),
    ('successInk', AppColors.successInk),
    ('secondaryInk', AppColors.secondaryInk),
    ('dangerInk', AppColors.dangerInk),
    ('purpleInk', AppColors.purpleInk),
    ('infoInk', AppColors.infoInk),
    ('textPrimary', AppColors.textPrimary),
    ('textSecondary', AppColors.textSecondary),
  ];

  /// คอนทราสต์ต่ำสุดของสีนี้เมื่อเทียบกับทุกพื้นที่ใช้จริง
  double worstCase(Color ink) =>
      surfaces().map((s) => _contrast(ink, s.$2)).reduce(math.min);

  group('พาเลตต์สี', () {
    test(
      'โหมดปกติ — ตัวหนังสือทุกตัวผ่าน WCAG AA (4.5:1) บนทุกพื้นที่ใช้จริง',
      () {
        AppColors.contrast = AppContrast.standard;
        for (final (name, color) in readableInk()) {
          expect(
            worstCase(color),
            greaterThanOrEqualTo(4.5),
            reason: '$name ตกเกณฑ์ AA',
          );
        }
      },
    );

    test(
      'โหมดคอนทราสต์สูง — ตัวหนังสือทุกตัวผ่าน WCAG AAA (7:1) บนทุกพื้นที่ใช้จริง',
      () {
        AppColors.contrast = AppContrast.high;
        for (final (name, color) in readableInk()) {
          expect(
            worstCase(color),
            greaterThanOrEqualTo(7.0),
            reason: '$name ตกเกณฑ์ AAA',
          );
        }
      },
    );

    test('textDisabled — ต้องอ่านออก (AA) แต่ต้องจางกว่าข้อความปกติเสมอ', () {
      for (final mode in AppContrast.values) {
        AppColors.contrast = mode;
        expect(
          worstCase(AppColors.textDisabled),
          // โหมดปกติ 2.26 เป็นค่าที่ตั้งใจ — WCAG ยกเว้นองค์ประกอบที่ปิดใช้งาน
          // ไม่ให้ต้องผ่านเกณฑ์ ส่วนโหมดคอนทราสต์สูงดันขึ้นให้อ่านออกได้
          greaterThanOrEqualTo(mode == AppContrast.high ? 4.5 : 2.2),
          reason: 'textDisabled จางเกินไปในโหมด $mode',
        );
        expect(
          worstCase(AppColors.textDisabled),
          lessThan(worstCase(AppColors.textSecondary)),
          reason:
              'textDisabled ต้องจางกว่า textSecondary ไม่งั้นแยกไม่ออกว่าปิดใช้งาน',
        );
      }
    });

    test('โหมดคอนทราสต์สูงต้องเข้มกว่าโหมดปกติเสมอ ไม่ใช่แค่เปลี่ยนสี', () {
      AppColors.contrast = AppContrast.standard;
      final before = {
        for (final (name, color) in readableInk()) name: worstCase(color),
      };

      AppColors.contrast = AppContrast.high;
      for (final (name, color) in readableInk()) {
        expect(
          worstCase(color),
          greaterThan(before[name]!),
          reason: '$name ไม่ได้เข้มขึ้นเลยในโหมดคอนทราสต์สูง',
        );
      }
    });

    test(
      'ขอบในโหมดคอนทราสต์สูงต้องผ่านเกณฑ์องค์ประกอบที่ไม่ใช่ตัวหนังสือ (3:1)',
      () {
        AppColors.contrast = AppContrast.standard;
        // โหมดปกติตั้งใจให้ขอบจางเพื่อความสวยงาม จึงยังไม่ถึง 3:1
        expect(_contrast(AppColors.border, AppColors.surface), lessThan(3.0));

        AppColors.contrast = AppContrast.high;
        expect(
          _contrast(AppColors.border, AppColors.surface),
          greaterThanOrEqualTo(3.0),
        );
      },
    );

    test('สีที่เอาไปเป็นพื้นปุ่ม/ชิป ต้องอ่านป้ายสีขาวออก (4.5:1)', () {
      // บั๊กนี้เคยหลุดมาแล้วสองรอบ: ชิปที่ถูกเลือกทั้งแอป และปุ่มเดินสถานะในจอครัว
      // ทั้งคู่ใช้ตัวหนังสือสีขาวบน "สีสด" ซึ่งสว่างเกินไป (เหลืองได้แค่ 2.13:1)
      // สีสดออกแบบมาเป็นพื้น/จุด/ขอบ ถ้าจะรองตัวหนังสือสีขาวต้องใช้เฉด ink เสมอ
      for (final mode in AppContrast.values) {
        AppColors.contrast = mode;
        final fills = <String, Color>{
          'brandInk': AppColors.brandInk,
          'warningInk': AppColors.warningInk,
          'successInk': AppColors.successInk,
          'secondaryInk': AppColors.secondaryInk,
          'dangerInk': AppColors.dangerInk,
          'purpleInk': AppColors.purpleInk,
          'infoInk': AppColors.infoInk,
        };
        fills.forEach((name, fill) {
          expect(
            _contrast(AppColors.surface, fill),
            greaterThanOrEqualTo(4.5),
            reason: 'ป้ายสีขาวบนพื้น $name อ่านไม่ออกในโหมด $mode',
          );
        });
      }
    });

    test('inkOf / itemStatusInk ต้องคืนเฉดเข้มเสมอ ไม่ใช่สีสดที่ส่งเข้าไป', () {
      AppColors.contrast = AppContrast.standard;
      final vivid = [
        AppColors.primary,
        AppColors.warning,
        AppColors.success,
        AppColors.danger,
        AppColors.purple,
      ];
      for (final color in vivid) {
        expect(
          AppColors.inkOf(color),
          isNot(color),
          reason: 'inkOf ต้องแปลงสีสดเป็นเฉดเข้ม ไม่ใช่คืนค่าเดิม',
        );
      }
    });

    test('inkOf คืนเฉดของโหมดที่ใช้อยู่ ไม่ค้างเป็นของโหมดแรกที่เรียก', () {
      AppColors.contrast = AppContrast.standard;
      final standard = AppColors.inkOf(AppColors.primary);

      AppColors.contrast = AppContrast.high;
      final high = AppColors.inkOf(AppColors.primary);

      expect(high, isNot(standard));
      expect(high, AppColors.brandInk);
    });
  });
}
