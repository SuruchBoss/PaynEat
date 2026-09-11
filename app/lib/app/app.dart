import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/localization/app_translations.dart';
import '../core/services/contrast_service.dart';
import '../core/services/storage_service.dart';
import 'config/app_config.dart';
import 'di/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class PaynEatApp extends StatelessWidget {
  const PaynEatApp({super.key});

  /// ภาษาที่ผู้ใช้เลือกไว้ล่าสุด (ถ้ามี) — ค่าเริ่มต้นคือไทย
  Locale get _initialLocale {
    final saved = Get.isRegistered<StorageService>()
        ? Get.find<StorageService>().locale
        : null;
    return saved == 'en' ? const Locale('en', 'US') : const Locale('th', 'TH');
  }

  @override
  Widget build(BuildContext context) {
    // ต้องคืนค่าคอนทราสต์ก่อนสร้างธีม ไม่งั้นเฟรมแรกจะวาดด้วยโหมดปกติแล้วค่อยกระพริบ
    ContrastService.restore();

    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 220),
      translations: AppTranslations(),
      locale: _initialLocale,
      fallbackLocale: AppTranslations.fallbackLocale,
      // ล็อกขนาดตัวอักษรไม่ให้ใหญ่เกินจนผังโต๊ะเพี้ยนบนแท็บเล็ตร้าน
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.2,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
