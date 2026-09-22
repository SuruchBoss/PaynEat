import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/localization/app_translations.dart';

/// ฟอนต์เกาหลีที่ฝังไว้เป็น subset เฉพาะตัวอักษรที่คำแปลใช้จริง (ดู pubspec.yaml)
/// ถ้ามีคนเพิ่มคำแปลเกาหลีที่ใช้ตัวอักษรนอก subset ตัวนั้นจะกลายเป็นกล่องสี่เหลี่ยม
/// บนหน้าจอจริงโดยไม่มีอะไรเตือน — เทสต์นี้อ่าน cmap ของไฟล์ฟอนต์จริงมาเทียบ
void main() {
  test('ทุกตัวอักษรในคำแปลเกาหลีต้องมี glyph อยู่ในฟอนต์ที่ฝังไว้', () {
    final translations = AppTranslations().keys['ko_KR'];
    expect(translations, isNotNull, reason: 'ยังไม่ได้ลงทะเบียน ko_KR');

    final used = <int>{};
    for (final value in translations!.values) {
      used.addAll(value.runes);
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
