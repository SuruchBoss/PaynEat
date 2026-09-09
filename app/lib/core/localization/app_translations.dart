import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'translations/auth_translations.dart';
import 'translations/common_translations.dart';
import 'translations/home_translations.dart';
import 'translations/kitchen_translations.dart';
import 'translations/menu_translations.dart';
import 'translations/order_translations.dart';
import 'translations/payment_translations.dart';
import 'translations/report_translations.dart';
import 'translations/settings_translations.dart';
import 'translations/shift_translations.dart';
import 'translations/staff_translations.dart';
import 'translations/status_translations.dart';
import 'translations/table_translations.dart';

/// รวมคำแปลทั้งแอป — ไทย (ค่าเริ่มต้น) และอังกฤษ
///
/// แต่ละฟีเจอร์มีไฟล์คำแปลของตัวเองใน translations/ เพื่อให้แก้ไขแยกกันได้
/// โดยไม่ชนกัน ไฟล์นี้แค่รวมทุกอย่างเข้าด้วยกัน
class AppTranslations extends Translations {
  static const List<Locale> supportedLocales = [
    Locale('th', 'TH'),
    Locale('en', 'US'),
  ];

  static const Locale fallbackLocale = Locale('en', 'US');

  @override
  Map<String, Map<String, String>> get keys => {
    'th_TH': {
      ...commonTranslationsTh,
      ...statusTranslationsTh,
      ...authTranslationsTh,
      ...homeTranslationsTh,
      ...kitchenTranslationsTh,
      ...menuTranslationsTh,
      ...orderTranslationsTh,
      ...paymentTranslationsTh,
      ...reportTranslationsTh,
      ...settingsTranslationsTh,
      ...shiftTranslationsTh,
      ...staffTranslationsTh,
      ...tableTranslationsTh,
    },
    'en_US': {
      ...commonTranslationsEn,
      ...statusTranslationsEn,
      ...authTranslationsEn,
      ...homeTranslationsEn,
      ...kitchenTranslationsEn,
      ...menuTranslationsEn,
      ...orderTranslationsEn,
      ...paymentTranslationsEn,
      ...reportTranslationsEn,
      ...settingsTranslationsEn,
      ...shiftTranslationsEn,
      ...staffTranslationsEn,
      ...tableTranslationsEn,
    },
  };
}
