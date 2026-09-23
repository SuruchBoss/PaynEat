import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/demo/demo_names.dart';
import 'package:payneat_pos/core/demo/demo_seed.dart';
import 'package:payneat_pos/core/demo/demo_store.dart';
import 'package:payneat_pos/core/localization/app_translations.dart';
import 'package:payneat_pos/core/localization/locale_service.dart';
import 'package:payneat_pos/core/utils/app_clock.dart';

/// กันอักษรไทยหลุดเข้าหน้าจอตอนผู้ใช้เลือกภาษาอื่น
///
/// เคสนี้ไม่ได้สมมติขึ้นเอง — ผู้ใช้ชาวเกาหลีเปิดหน้าจริงแล้วทักกลับมาว่า
/// "ภาพประกอบยังติดภาษาไทย เค้าอาจจะคิดว่าเรารองรับภาษาเกาหลีจริงไหม"
/// ตอนนั้นชื่อโซนบนหน้าที่ลูกค้าสแกน QR เห็น ชื่อร้านและชื่อพนักงานบนใบเสร็จ
/// ยังเป็นภาษาไทยอยู่ ทั้งที่ UI รอบ ๆ เป็นเกาหลีหมดแล้ว
///
/// เทสต์นี้ไล่ "ข้อมูลที่ไปโผล่บนหน้าจอ" ไม่ใช่แค่ไฟล์คำแปล เพราะจุดที่หลุด
/// ทุกจุดคือข้อมูล ไม่ใช่คำแปล
///
/// **วนตาม supportedLocales ไม่ได้ระบุภาษาเอง** — ตอนทำเกาหลีเสร็จแล้วมาไล่ดู
/// พบว่าผู้ใช้อังกฤษยังเห็นชื่อโซนเป็นภาษาไทยอยู่ 4 โซน เพราะเติมแต่ `zoneKo`
/// ลืม `zoneEn` การเติมภาษาใหม่ทีละภาษาทำให้ภาษาที่มีอยู่เดิมถูกทิ้งไว้ข้างหลัง
/// ได้ง่ายมาก และไม่มีอะไรฟ้องเลยถ้าเทสต์ระบุแค่ภาษาที่เพิ่งทำ
void main() {
  /// ช่วงโค้ดพอยต์ของอักษรไทย
  bool hasThai(String value) =>
      value.runes.any((rune) => rune >= 0x0E00 && rune <= 0x0E7F);

  /// ทุกภาษาที่รองรับ ยกเว้นไทย (ไทยเป็นภาษาต้นทาง ย่อมมีอักษรไทยอยู่แล้ว)
  final nonThai = AppTranslations.supportedLocales
      .map((locale) => locale.languageCode)
      .where((code) => code != 'th')
      .toList();

  setUpAll(() {
    AppClock.freeze(DateTime(2026, 9, 11, 19, 42));
    DemoStore.instance.reset();
  });

  tearDownAll(() {
    AppClock.unfreeze();
    DemoNames.language = 'th';
    Get.locale = LocaleService.thai;
    DemoStore.instance.reset();
  });

  test('มีภาษาที่ต้องตรวจอย่างน้อย 1 ภาษา', () {
    // กันเคสที่ supportedLocales ถูกแก้จนเหลือไทยภาษาเดียว แล้วเทสต์ข้างล่าง
    // ไม่รันสักข้อแต่ผลออกมาเขียวหมด
    expect(nonThai, isNotEmpty);
  });

  for (final lang in nonThai) {
    test(
      '[$lang] ชื่อเมนู หมวดหมู่ และตัวเลือกเสริม ต้องไม่มีอักษรไทยเหลือ',
      () {
        final offenders = <String>{};
        for (final row in [...DemoSeed.categories(), ...DemoSeed.menuItems()]) {
          final name = DemoNames.of(row, lang: lang);
          if (hasThai(name)) offenders.add(name);
          for (final group in (row['optionGroups'] as List? ?? const [])) {
            final g = (group as Map).cast<String, dynamic>();
            final groupName = DemoNames.of(g, lang: lang);
            if (hasThai(groupName)) offenders.add(groupName);
            for (final option in (g['options'] as List? ?? const [])) {
              final o = DemoNames.of(
                (option as Map).cast<String, dynamic>(),
                lang: lang,
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
      },
    );

    test('[$lang] ชื่อโซนโต๊ะต้องไม่มีอักษรไทยเหลือ', () {
      final offenders = DemoSeed.tables()
          .map((table) => DemoNames.of(table, lang: lang, key: 'zone'))
          .where(hasThai)
          .toSet();
      expect(
        offenders,
        isEmpty,
        reason: 'ยังเป็นภาษาไทย: ${offenders.join(', ')}',
      );
    });

    test('[$lang] ชื่อร้านและชื่อพนักงานต้องไม่มีอักษรไทยเหลือ', () {
      final store = DemoNames.of(
        DemoSeed.settings(),
        lang: lang,
        key: 'storeName',
      );
      expect(hasThai(store), isFalse, reason: 'ชื่อร้านยังเป็นภาษาไทย: $store');

      final staff = DemoSeed.users()
          .map((user) => DemoNames.of(user, lang: lang))
          .where(hasThai)
          .toList();
      expect(
        staff,
        isEmpty,
        reason: 'ชื่อพนักงานยังเป็นภาษาไทย: ${staff.join(', ')}',
      );
    });
  }

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
