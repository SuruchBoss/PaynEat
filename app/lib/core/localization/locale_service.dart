import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/storage_service.dart';

/// สลับภาษาทั้งแอปและจำค่าไว้ในเครื่อง
class LocaleService {
  const LocaleService._();

  static const Locale thai = Locale('th', 'TH');
  static const Locale english = Locale('en', 'US');
  static const Locale korean = Locale('ko', 'KR');

  /// ภาษาที่ใช้อยู่ — ถอยไปไทยถ้ายังไม่ได้ตั้งค่า
  static String get languageCode => Get.locale?.languageCode ?? 'th';

  static bool get isThai => languageCode == 'th';
  static bool get isEnglish => languageCode == 'en';
  static bool get isKorean => languageCode == 'ko';

  /// ควรใช้ชื่อเมนู/หมวดหมู่ที่เป็นภาษาอังกฤษไหม
  ///
  /// ข้อมูลเมนูมีแค่ชื่อไทยกับชื่ออังกฤษ ไม่มีชื่อเกาหลี — ผู้ใช้ที่ไม่ได้อ่านไทย
  /// จึงควรได้ชื่ออังกฤษ ไม่ใช่ชื่อไทยที่อ่านไม่ออก เงื่อนไขจึงเป็น "ไม่ใช่ไทย"
  /// ไม่ใช่ "เป็นอังกฤษ" เพื่อให้ภาษาที่เพิ่มเข้ามาทีหลังได้พฤติกรรมนี้เอง
  static bool get prefersLatinNames => !isThai;

  static Locale localeOf(String code) => switch (code) {
    'en' => english,
    'ko' => korean,
    _ => thai,
  };

  static Future<void> change(Locale locale) async {
    Get.updateLocale(locale);
    if (Get.isRegistered<StorageService>()) {
      await Get.find<StorageService>().saveLocale(locale.languageCode);
    }
  }
}
