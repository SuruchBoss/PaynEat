import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'config/app_config.dart';
import 'di/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class PaynEatApp extends StatelessWidget {
  const PaynEatApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      locale: const Locale('th', 'TH'),
      fallbackLocale: const Locale('en', 'US'),
      // ล็อกขนาดตัวอักษรไม่ให้ใหญ่เกินจนผังโต๊ะเพี้ยนบนแท็บเล็ตร้าน
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.2,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
