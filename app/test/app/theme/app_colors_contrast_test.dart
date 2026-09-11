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

  /// ตัวหนังสือ/ไอคอนที่ต้องอ่านออกบนพื้นสว่าง
  List<(String, Color)> inkTokens() => [
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

  group('พาเลตต์สี', () {
    test('โหมดปกติ — ตัวหนังสือทุกตัวผ่าน WCAG AA (4.5:1) บนพื้นขาว', () {
      AppColors.contrast = AppContrast.standard;
      for (final (name, color) in inkTokens()) {
        expect(
          _contrast(color, AppColors.surface),
          greaterThanOrEqualTo(4.5),
          reason: '$name ตกเกณฑ์ AA',
        );
      }
    });

    test('โหมดคอนทราสต์สูง — ตัวหนังสือทุกตัวผ่าน WCAG AAA (7:1)', () {
      AppColors.contrast = AppContrast.high;
      for (final (name, color) in inkTokens()) {
        expect(
          _contrast(color, AppColors.surface),
          greaterThanOrEqualTo(7.0),
          reason: '$name ตกเกณฑ์ AAA',
        );
      }
    });

    test('โหมดคอนทราสต์สูงต้องเข้มกว่าโหมดปกติเสมอ ไม่ใช่แค่เปลี่ยนสี', () {
      AppColors.contrast = AppContrast.standard;
      final before = {
        for (final (name, color) in inkTokens())
          name: _contrast(color, AppColors.surface),
      };

      AppColors.contrast = AppContrast.high;
      for (final (name, color) in inkTokens()) {
        expect(
          _contrast(color, AppColors.surface),
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
