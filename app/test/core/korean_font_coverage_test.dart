import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/demo/demo_names.dart';
import 'package:payneat_pos/core/demo/demo_seed.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/localization/app_translations.dart';
import 'package:payneat_pos/core/localization/locale_service.dart';
import 'package:payneat_pos/core/utils/formatters.dart';

/// ฟอนต์เกาหลีที่ฝังไว้เป็น subset เฉพาะตัวอักษรที่คำแปลใช้จริง (ดู pubspec.yaml)
/// ถ้ามีคนเพิ่มคำแปลเกาหลีที่ใช้ตัวอักษรนอก subset ตัวนั้นจะกลายเป็นกล่องสี่เหลี่ยม
/// บนหน้าจอจริงโดยไม่มีอะไรเตือน — เทสต์นี้อ่าน cmap ของไฟล์ฟอนต์จริงมาเทียบ
void main() {
  test('ทุกตัวอักษรภาษาเกาหลีที่แอปแสดงต้องมี glyph อยู่ในฟอนต์ที่ฝังไว้', () {
    final translations = AppTranslations().keys['ko_KR'];
    expect(translations, isNotNull, reason: 'ยังไม่ได้ลงทะเบียน ko_KR');

    final used = <int>{};
    for (final value in translations!.values) {
      used.addAll(value.runes);
    }

    // ข้อมูลสาธิตก็ถูกวาดด้วยฟอนต์เดียวกัน และเป็นสิ่งที่คนกดเข้ามาลองเห็นก่อน
    // คำแปล UI ด้วยซ้ำ — รอบแรกตรวจแค่คำแปล ชื่อเมนูภาษาเกาหลีจึงหลุดออกนอก
    // subset ได้โดยไม่มีอะไรฟ้อง
    //
    // รอบที่สองยังตกอีก 3 แหล่ง จนไปโผล่เป็นกล่องสี่เหลี่ยมกลางใบเสร็จ
    // ("할□니 부□", "2026□ 9월", "□지은") — ชื่อร้านใช้คีย์ storeName ไม่ใช่ name,
    // ชื่อพนักงานอยู่ใน users() ซึ่งไม่ได้อยู่ในลิสต์, และตัวอักษร 년/월/일
    // มาจาก pattern ของ DateFormat ไม่ได้อยู่ในข้อมูลสักชุด
    // บทเรียน: ต้องไล่จาก "สิ่งที่วาดบนจอ" ไม่ใช่ "ไฟล์ที่นึกออก"
    used.addAll(
      DemoNames.of(DemoSeed.settings(), lang: 'ko', key: 'storeName').runes,
    );
    for (final user in DemoSeed.users()) {
      used.addAll(DemoNames.of(user, lang: 'ko').runes);
    }
    // รูปแบบวันที่ภาษาเกาหลีมีตัวอักษรเกาหลีฝังอยู่ใน pattern เอง
    // เรียกผ่าน Formatters จริงแทนการพิมพ์ '년월일' ซ้ำไว้ในเทสต์
    // ถ้าวันหนึ่งมีคนเปลี่ยน pattern เทสต์จะตามไปเอง
    Get.locale = LocaleService.korean;
    used.addAll(Formatters.dateTime('2026-09-11T12:42:00Z').runes);
    used.addAll(Formatters.date(DateTime(2026, 9, 11)).runes);
    Get.locale = LocaleService.thai;

    for (final row in [
      ...DemoSeed.categories(),
      ...DemoSeed.menuItems(),
      ...DemoSeed.tables(),
    ]) {
      used.addAll(DemoNames.of(row, lang: 'ko').runes);
      final zoneKo = row['zoneKo'] as String?;
      if (zoneKo != null) used.addAll(zoneKo.runes);
      for (final group in (row['optionGroups'] as List? ?? const [])) {
        final g = (group as Map).cast<String, dynamic>();
        used.addAll(DemoNames.of(g, lang: 'ko').runes);
        for (final option in (g['options'] as List? ?? const [])) {
          used.addAll(
            DemoNames.of(
              (option as Map).cast<String, dynamic>(),
              lang: 'ko',
            ).runes,
          );
        }
      }
    }

    final covered = _cmapOf('assets/fonts/NotoSansKR-400.ttf')
      ..addAll(_cmapOf('assets/fonts/NotoSansThai-400.ttf'));

    // ตัวอักษรที่ไม่ต้องมีในฟอนต์: อีโมจิ (ระบบปฏิบัติการวาดเอง) และช่องว่าง
    bool needsGlyph(int rune) =>
        rune > 0x20 && !(rune >= 0x1F000 && rune <= 0x1FAFF);

    final missing = used.where(needsGlyph).where((r) => !covered.contains(r));

    expect(
      missing,
      isEmpty,
      reason:
          'อักษรเหล่านี้ไม่มีในฟอนต์ที่ฝังไว้ จะขึ้นเป็นกล่องบนหน้าจอจริง: '
          '${missing.map((r) => String.fromCharCode(r)).join()} — '
          'ต้อง subset ฟอนต์ใหม่ (ดู docs/DECISIONS.md)',
    );
  });
}

/// อ่านตาราง cmap ของไฟล์ TrueType ตรง ๆ — คืนชุด code point ที่ฟอนต์รองรับ
Set<int> _cmapOf(String path) {
  final bytes = File(path).readAsBytesSync().buffer.asByteData();
  final numTables = bytes.getUint16(4);

  var cmapOffset = -1;
  for (var i = 0; i < numTables; i++) {
    final rec = 12 + i * 16;
    final tag = String.fromCharCodes(
      List.generate(4, (j) => bytes.getUint8(rec + j)),
    );
    if (tag == 'cmap') cmapOffset = bytes.getUint32(rec + 8);
  }
  if (cmapOffset < 0) return <int>{};

  // เลือก subtable แบบ format 4 (Unicode BMP) ซึ่ง Noto ใช้เป็นหลัก
  final numSub = bytes.getUint16(cmapOffset + 2);
  var best = -1;
  for (var i = 0; i < numSub; i++) {
    final rec = cmapOffset + 4 + i * 8;
    final platform = bytes.getUint16(rec);
    final encoding = bytes.getUint16(rec + 2);
    final offset = cmapOffset + bytes.getUint32(rec + 4);
    final isUnicode = platform == 0 || (platform == 3 && encoding >= 1);
    if (isUnicode && bytes.getUint16(offset) == 4) best = offset;
  }
  if (best < 0) return <int>{};

  final segCount = bytes.getUint16(best + 6) ~/ 2;
  final endBase = best + 14;
  final startBase = endBase + segCount * 2 + 2;

  final out = <int>{};
  for (var s = 0; s < segCount; s++) {
    final end = bytes.getUint16(endBase + s * 2);
    final start = bytes.getUint16(startBase + s * 2);
    if (start > end || end == 0xFFFF) continue;
    for (var c = start; c <= end; c++) {
      out.add(c);
    }
  }
  return out;
}
