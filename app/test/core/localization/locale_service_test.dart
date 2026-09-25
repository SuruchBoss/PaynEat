import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/app/app.dart';
import 'package:payneat_pos/core/localization/app_translations.dart';
import 'package:payneat_pos/core/localization/locale_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';

/// กันบั๊กที่เพิ่งเจอตอนทำภาษาเกาหลี: `PaynEatApp._initialLocale` เดิมเขียนว่า
/// `saved == 'en' ? อังกฤษ : ไทย` ผู้ใช้ที่เลือกเกาหลีไว้จึงเปิดแอปมาเจอภาษาไทย
/// ทั้งที่คำแปลครบทุกคีย์ — ไม่มีอะไรฟ้องเลยเพราะโค้ดยัง compile ผ่านปกติ
///
/// เทสต์นี้ผูกกับ `supportedLocales` โดยตรง เพิ่มภาษาที่ 4 เมื่อไหร่
/// แล้วลืมแก้ตัวแปลงรหัสภาษา เทสต์จะแดงทันทีโดยไม่ต้องเพิ่มเคสเอง
void main() {
  group('LocaleService.localeOf', () {
    test('ทุกภาษาใน supportedLocales ต้องแปลงกลับจากรหัสได้ตรงตัว', () {
      for (final locale in AppTranslations.supportedLocales) {
        expect(
          LocaleService.localeOf(locale.languageCode),
          locale,
          reason:
              'รหัส "${locale.languageCode}" อยู่ใน supportedLocales '
              'แต่ localeOf() แปลงกลับไม่ตรง — '
              'ดู LocaleService.localeOf ว่าลืมใส่ case ของภาษานี้หรือเปล่า',
        );
      }
    });

    test('รหัสที่ไม่รู้จักหรือค่าว่าง ตกกลับเป็นภาษาไทย', () {
      expect(LocaleService.localeOf('ja'), LocaleService.thai);
      expect(LocaleService.localeOf(''), LocaleService.thai);
    });
  });

  group('LocaleService.prefersLatinNames', () {
    setUp(Get.reset);
    tearDownAll(Get.reset);

    // ข้อมูลเมนูมีแค่ชื่อไทยกับชื่ออังกฤษ ผู้ใช้เกาหลีจึงต้องได้ชื่ออังกฤษ
    // ไม่ใช่ชื่อไทยที่อ่านไม่ออก — เงื่อนไขจึงต้องเป็น "ไม่ใช่ไทย"
    // ไม่ใช่ "เป็นอังกฤษ" อย่างที่เขียนไว้ตอนมีแค่สองภาษา
    test('เกาหลีต้องได้ชื่อเมนูอักษรละติน เหมือนอังกฤษ', () {
      Get.locale = LocaleService.korean;
      expect(LocaleService.isKorean, isTrue);
      expect(LocaleService.prefersLatinNames, isTrue);
    });

    test('ไทยยังได้ชื่อเมนูภาษาไทย', () {
      Get.locale = LocaleService.thai;
      expect(LocaleService.prefersLatinNames, isFalse);
    });
  });

  // เทสต์ข้างบนคุม "ตัวแปลงรหัสภาษา" แต่บั๊กจริงอยู่ที่ "คนเรียกใช้" —
  // จึงต้องวางแอปจริงลงไปแล้วดูว่า Get.locale ออกมาเป็นภาษาที่เซฟไว้จริงไหม
  group('PaynEatApp คืนภาษาที่เคยเลือกไว้', () {
    tearDown(Get.reset);

    for (final locale in AppTranslations.supportedLocales) {
      testWidgets('เซฟ "${locale.languageCode}" ไว้ เปิดแอปมาต้องได้ภาษานั้น', (
        tester,
      ) async {
        Get.reset();
        final storage = StorageService.memory();
        await storage.saveLocale(locale.languageCode);
        Get.put<StorageService>(storage, permanent: true);

        await tester.pumpWidget(const PaynEatApp());
        await tester.pump();

        expect(
          Get.locale,
          locale,
          reason:
              'เซฟภาษา "${locale.languageCode}" ไว้แล้วแต่แอปเปิดมาเป็น '
              '${Get.locale} — ดู PaynEatApp._initialLocale',
        );
      });
    }
  });

  // ปฏิทินเลือกวัน/ปุ่มคัดลอก-วาง/ปุ่มยกเลิกของกล่องมาตรฐานมาจาก MaterialLocalizations
  // เดิมไม่ได้ผูก delegates ไว้ ทุกภาษาจึงได้ภาษาอังกฤษ (DECISIONS #64)
  group('PaynEatApp ข้อความมาตรฐานของ Material ตามภาษาแอป', () {
    tearDown(Get.reset);

    for (final (locale, cancel) in [
      (LocaleService.thai, 'ยกเลิก'),
      (LocaleService.english, 'Cancel'),
      (LocaleService.korean, '취소'),
    ]) {
      testWidgets(
        '${locale.languageCode} → ปุ่มยกเลิกของ Material เป็น "$cancel"',
        (tester) async {
          Get.reset();
          final storage = StorageService.memory();
          await storage.saveLocale(locale.languageCode);
          Get.put<StorageService>(storage, permanent: true);

          await tester.pumpWidget(const PaynEatApp());
          await tester.pump();

          final context = tester.element(find.byType(Navigator).first);
          expect(MaterialLocalizations.of(context).cancelButtonLabel, cancel);
        },
      );
    }
  });

  // UAT แบบไม่มีคนสอน: เปิดแอปครั้งแรก (ยังไม่เคยเลือกภาษา) ต้องได้ภาษาเครื่อง ถ้าแอปรองรับ
  // เดิมเป็นไทยเสมอ พนักงานเกาหลีเปิดมาเจอหน้าไทยแล้วหาทางเปลี่ยนไม่เจอ (DECISIONS #62)
  group('PaynEatApp ครั้งแรกใช้ภาษาเครื่อง', () {
    tearDown(Get.reset);

    for (final (device, expected) in [
      (const Locale('ko', 'KR'), LocaleService.korean),
      (const Locale('en', 'US'), LocaleService.english),
      (const Locale('ja', 'JP'), LocaleService.thai),
    ]) {
      testWidgets('เครื่องเป็น $device → เปิดมาเป็น ${expected.languageCode}', (
        tester,
      ) async {
        Get.reset();
        tester.platformDispatcher.localesTestValue = [device];
        tester.platformDispatcher.localeTestValue = device;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        Get.put<StorageService>(StorageService.memory(), permanent: true);

        await tester.pumpWidget(const PaynEatApp());
        await tester.pump();

        expect(Get.locale, expected);
      });
    }
  });

  // `LocaleService.change` เองเทสต์ตรง ๆ ไม่ได้ — `Get.updateLocale` เรียก
  // `runApp` ซ้ำเพื่อ reassemble ซึ่ง binding ของ flutter_test ไม่ยอมให้ทำ
  // นอกเส้นทาง `pumpWidget` สิ่งที่เทสต์ได้และเป็นจุดที่เคยพังจริงคือ "สัญญา"
  // ของมัน: เซฟด้วย languageCode แล้วรอบหน้าต้องอ่านกลับมาได้ภาษาเดิม
  group('รหัสภาษาที่เซฟลง storage ต้องวนกลับมาได้ครบรอบ', () {
    for (final locale in AppTranslations.supportedLocales) {
      test('${locale.languageCode} — เซฟแล้วอ่านกลับได้ตรงตัว', () async {
        final storage = StorageService.memory();

        // เซฟด้วย languageCode อย่างเดียว ตรงกับที่ LocaleService.change ทำ
        await storage.saveLocale(locale.languageCode);

        expect(storage.locale, locale.languageCode);
        expect(LocaleService.localeOf(storage.locale!), locale);
      });
    }
  });
}
