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

  // เว้น margin บนให้พ้นความสูง AppBar เสมอ (ไม่ให้ทับข้อความ/ไอคอนบน AppBar สายตา)
  static const _topMargin = EdgeInsets.fromLTRB(
    12,
    kToolbarHeight + 12,
    12,
    12,
  );

  // GetX ห่อ snackbar ที่ isDismissible (ค่าเริ่มต้น) ด้วย Dismissible ซึ่งพื้นที่รับสัมผัส
  // จริงคือกรอบนอกทั้งก้อนรวม margin ด้วย ไม่ใช่แค่ตัวการ์ดที่มองเห็น — ผลคือปุ่มย้อนกลับ/ไอคอน
  // บน AppBar กดไม่ติดตลอดช่วงที่ snackbar ค้างอยู่ (2-3 วิ) ต่อให้เว้น margin ให้พ้นสายตาแล้วก็ตาม
  // (พบจากการทดสอบจริง) ปิด isDismissible เพราะ toast พวกนี้ไม่ต้องให้ปัดปิดเองอยู่แล้ว
  // (auto-dismiss ตาม duration) จึงไม่จำเป็นต้องมี gesture wrapper ดักสัมผัสไว้เลย
  static const _dismissible = false;

  static void success(String message, {String? title}) {
    Get.snackbar(
      title ?? 'common_success_title'.tr,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.fillOf(AppColors.success),
      colorText: AppColors.onColor(AppColors.fillOf(AppColors.success)),
      margin: _topMargin,
      isDismissible: _dismissible,
      icon: Icon(
        Icons.check_circle_rounded,
        color: AppColors.onColor(AppColors.fillOf(AppColors.success)),
      ),
      duration: const Duration(seconds: 2),
    );
  }

  static void error(String message, {String? title}) {
    Get.snackbar(
      title ?? 'common_error_title'.tr,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.fillOf(AppColors.danger),
      colorText: AppColors.onColor(AppColors.fillOf(AppColors.danger)),
      margin: _topMargin,
      isDismissible: _dismissible,
      icon: Icon(
        Icons.error_rounded,
        color: AppColors.onColor(AppColors.fillOf(AppColors.danger)),
      ),
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
      margin: _topMargin,
      isDismissible: _dismissible,
      duration: const Duration(seconds: 2),
    );
  }
}
