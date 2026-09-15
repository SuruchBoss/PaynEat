import 'dart:async';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:payneat_pos/core/localization/app_translations.dart';

/// Flutter รันไฟล์นี้อัตโนมัติก่อนเทสต์ทุกไฟล์ในแพ็กเกจนี้ (ไม่ต้อง import เอง)
///
/// ตั้งค่าระบบแปลภาษาของ GetX ไว้ล่วงหน้า เพราะโค้ดจริง (AppConstants label,
/// AppDialogs, exceptions ฯลฯ) เรียก `.tr` อยู่ทั่วไป — ถ้าไม่ตั้งค่าไว้ก่อน
/// `.tr` จะคืนคีย์ดิบแทนข้อความไทย ทำให้เทสต์ที่เช็คข้อความจริงพังหมด
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Get.addTranslations(AppTranslations().keys);
  Get.locale = const Locale('th', 'TH');
  Get.fallbackLocale = AppTranslations.fallbackLocale;
  await testMain();
}
