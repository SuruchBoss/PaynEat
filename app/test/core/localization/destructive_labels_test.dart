// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/localization/app_translations.dart';

/// ปุ่ม "ยกเลิกเอกสาร" (void — ทำลายเอกสารที่ออกไปแล้ว) ต้องไม่ใช้คำเดียวกับปุ่ม "ยกเลิก" ของกล่องโต้ตอบ
///
/// เจอตอนตรวจ UI หลัง ticket 21–23: ฉบับเกาหลีเขียนทั้งสองปุ่มว่า "취소" แล้ววางคู่กับ "닫기" ในกล่อง
/// เอกสารลูกหนี้ — คนที่อยากปิดกล่องกด "취소" แล้วเจอหน้าให้กรอกเหตุผลยกเลิกใบเสร็จ/ใบวางบิล
/// วนทุกภาษาที่รองรับ ไม่ใช่แค่เกาหลี เพราะภาษาถัดไปก็พลาดแบบเดียวกันได้
void main() {
  final keys = AppTranslations().keys;

  for (final locale in AppTranslations.supportedLocales) {
    final tag = '${locale.languageCode}_${locale.countryCode}';
    final strings = keys[tag] ?? keys[locale.languageCode]!;

    test('[$tag] ปุ่ม void ของเอกสารลูกหนี้ไม่ซ้ำกับปุ่มยกเลิก/ปิดทั่วไป', () {
      final voidLabel = strings['receivable_void_button'];
      expect(voidLabel, isNotNull);
      expect(voidLabel, isNot(strings['common_cancel']));
      expect(voidLabel, isNot(strings['common_close']));
    });
  }
}
