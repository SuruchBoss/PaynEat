import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';

/// รวม dialog / snackbar ที่ใช้บ่อย เพื่อให้ข้อความแจ้งเตือนทั้งแอปหน้าตาเหมือนกัน
class AppDialogs {
  const AppDialogs._();

  static Future<bool> confirm({
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    confirmLabel ??= 'common_confirm'.tr;
    cancelLabel ??= 'common_cancel'.tr;
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              cancelLabel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
                : null,
            onPressed: () => Get.back(result: true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static void success(String message, {String? title}) {
    Get.snackbar(
      title ?? 'common_success_title'.tr,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  static void error(String message, {String? title}) {
    Get.snackbar(
      title ?? 'common_error_title'.tr,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.danger,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      icon: const Icon(Icons.error_rounded, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  static void info(String message, {String? title}) {
    Get.snackbar(
      title ?? 'common_info_title'.tr,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.textPrimary,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }
}
