import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/demo/demo_names.dart';
import 'package:payneat_pos/core/demo/demo_seed.dart';
import 'package:payneat_pos/core/demo/demo_store.dart';
import 'package:payneat_pos/core/localization/locale_service.dart';
import 'package:payneat_pos/core/utils/app_clock.dart';

/// กันอักษรไทยหลุดเข้าหน้าจอตอนเลือกภาษาเกาหลี
///
/// เคสนี้ไม่ได้สมมติขึ้นเอง — ผู้ใช้ชาวเกาหลีเปิดหน้าจริงแล้วทักกลับมาว่า
/// "ภาพประกอบยังติดภาษาไทย เค้าอาจจะคิดว่าเรารองรับภาษาเกาหลีจริงไหม"
/// ตอนนั้นชื่อโซนบนหน้าที่ลูกค้าสแกน QR เห็น ชื่อร้านและชื่อพนักงานบนใบเสร็จ
/// ยังเป็นภาษาไทยอยู่ ทั้งที่ UI รอบ ๆ เป็นเกาหลีหมดแล้ว
///
/// เทสต์นี้ไล่ "ข้อมูลที่ไปโผล่บนหน้าจอ" ไม่ใช่แค่ไฟล์คำแปล เพราะจุดที่หลุด
/// ทุกจุดคือข้อมูล ไม่ใช่คำแปล
void main() {
  /// ช่วงโค้ดพอยต์ของอักษรไทย
  bool hasThai(String value) =>
      value.runes.any((rune) => rune >= 0x0E00 && rune <= 0x0E7F);

  setUpAll(() {
    AppClock.freeze(DateTime(2026, 9, 11, 19, 42));
    Get.locale = LocaleService.korean;
    DemoNames.language = 'ko';
    DemoStore.instance.reset();
  });

  tearDownAll(() {
    AppClock.unfreeze();
    DemoNames.language = 'th';
    Get.locale = LocaleService.thai;
    DemoStore.instance.reset();
  });

  test('ชื่อเมนู หมวดหมู่ และตัวเลือกเสริม ต้องไม่มีอักษรไทยเหลือ', () {
    final offenders = <String>[];
    for (final row in [...DemoSeed.categories(), ...DemoSeed.menuItems()]) {
      final name = DemoNames.of(row, lang: 'ko');
      if (hasThai(name)) offenders.add(name);
      for (final group in (row['optionGroups'] as List? ?? const [])) {
        final g = (group as Map).cast<String, dynamic>();
        final groupName = DemoNames.of(g, lang: 'ko');
        if (hasThai(groupName)) offenders.add(groupName);
        for (final option in (g['options'] as List? ?? const [])) {
          final o = DemoNames.of(
            (option as Map).cast<String, dynamic>(),
            lang: 'ko',
          );
          if (hasThai(o)) offenders.add(o);
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'ยังเป็นภาษาไทย: ${offenders.join(', ')}',
    );
  });

  test('ชื่อโซนโต๊ะต้องไม่มีอักษรไทยเหลือ', () {
    final offenders = DemoSeed.tables()
        .map((table) => DemoNames.of(table, lang: 'ko', key: 'zone'))
        .where(hasThai)
        .toList();
    expect(
      offenders,
      isEmpty,
      reason: 'ยังเป็นภาษาไทย: ${offenders.join(', ')}',
    );
  });

  test('ชื่อร้านและชื่อพนักงานต้องไม่มีอักษรไทยเหลือ', () {
    final store = DemoNames.of(
      DemoSeed.settings(),
      lang: 'ko',
      key: 'storeName',
    );
    expect(hasThai(store), isFalse, reason: 'ชื่อร้านยังเป็นภาษาไทย: $store');

    final staff = DemoSeed.users()
        .map((user) => DemoNames.of(user, lang: 'ko'))
        .where(hasThai)
        .toList();
    expect(
      staff,
      isEmpty,
      reason: 'ชื่อพนักงานยังเป็นภาษาไทย: ${staff.join(', ')}',
    );
  });

  // ที่อยู่ร้านกับชื่อสาขาเป็นข้อยกเว้นที่ "ต้อง" เป็นภาษาไทย — ใบกำกับภาษีของไทย
  // บังคับให้แสดงที่อยู่ตามที่จดทะเบียนไว้ ต่อให้หน้าจอเป็นภาษาอื่นก็ตาม
  // ถ้าวันหนึ่งมีคนไปแปลทิ้ง เทสต์นี้จะเตือนว่ากำลังทำผิดกฎหมายภาษีไทย
  test(
    'ที่อยู่ร้านและชื่อสาขาต้องคงเป็นภาษาไทยเสมอ (ข้อบังคับใบกำกับภาษี)',
    () {
      final settings = DemoSeed.settings();
      expect(
        hasThai(settings['storeAddress'] as String),
        isTrue,
        reason: 'ที่อยู่บนใบกำกับภาษีต้องเป็นภาษาไทยตามที่จดทะเบียน',
      );
      expect(hasThai(settings['storeBranch'] as String), isTrue);
    },
  );
}
