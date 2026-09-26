// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import '../core/demo/demo_names.dart';
import '../core/localization/app_translations.dart';
import '../core/localization/locale_service.dart';
import '../core/services/contrast_service.dart';
import '../core/services/storage_service.dart';
import 'config/app_config.dart';
import 'di/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class PaynEatApp extends StatelessWidget {
  const PaynEatApp({super.key});

  /// ภาษาที่ผู้ใช้เลือกไว้ล่าสุด (ถ้ามี) — ยังไม่เคยเลือก ใช้ภาษาของเครื่องถ้ารองรับ ไม่งั้นไทย
  ///
  /// ลูกค้าเกาหลีสแกน QR ด้วยมือถือตัวเองครั้งแรกต้องเห็นเมนูภาษาเกาหลีเลย ไม่ใช่ไทย
  /// (docs/DECISIONS.md #62)
  ///
  /// แปลงรหัสภาษาผ่าน [LocaleService.localeOf] จุดเดียว ไม่เทียบ `== 'en'` เอง
  /// ตรงนี้ — ตอนเพิ่มภาษาเกาหลีโค้ดเดิมยังคืนไทยให้ผู้ใช้ที่เลือก ko ไว้
  /// เพราะลืมแก้เงื่อนไขนี้ตามไปด้วย
  Locale get _initialLocale {
    final saved = Get.isRegistered<StorageService>()
        ? Get.find<StorageService>().locale
        : null;
    return LocaleService.localeOf(saved ?? LocaleService.deviceLanguageCode);
  }

  @override
  Widget build(BuildContext context) {
    // ต้องคืนค่าคอนทราสต์ก่อนสร้างธีม ไม่งั้นเฟรมแรกจะวาดด้วยโหมดปกติแล้วค่อยกระพริบ
    ContrastService.restore();

    final locale = _initialLocale;
    // ต้องบอกชั้นข้อมูลสาธิตตั้งแต่ก่อน build เฟรมแรก — `Get.locale` ยังไม่ถูกตั้ง
    // ตรงนี้ (GetMaterialApp เป็นคนตั้งให้ทีหลัง) ถ้ารอ `syncDemoNames()` ใน
    // `LocaleService.change` อย่างเดียว คนที่เปิดแอปมาเป็นภาษาเกาหลีอยู่แล้ว
    // โดยไม่ได้กดสลับภาษาจะได้ชื่อเมนูภาษาไทยไปทั้งกะ
    DemoNames.language = locale.languageCode;

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
      locale: locale,
      fallbackLocale: AppTranslations.fallbackLocale,
      // ไม่มีสามบรรทัดนี้ ปฏิทินเลือกวัน/ปุ่มคัดลอก-วาง/tooltip ย้อนกลับเป็นภาษาอังกฤษทุกภาษา
      supportedLocales: AppTranslations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // ล็อกขนาดตัวอักษรไม่ให้ใหญ่เกินจนผังโต๊ะเพี้ยนบนแท็บเล็ตร้าน
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.2,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
