import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/storage_service.dart';

/// สลับภาษาทั้งแอปและจำค่าไว้ในเครื่อง
class LocaleService {
  const LocaleService._();

  static bool get isEnglish => Get.locale?.languageCode == 'en';

  static Future<void> change(Locale locale) async {
    Get.updateLocale(locale);
    if (Get.isRegistered<StorageService>()) {
      await Get.find<StorageService>().saveLocale(locale.languageCode);
    }
  }
}
