import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

/// ถามเหตุผลก่อนยกเลิกเอกสาร (ใบเสร็จรับชำระ/ใบวางบิล) — คืน null ถ้ากดปิด
/// เหตุผลถูกบันทึกลง audit log ทุกครั้ง จึงบังคับกรอก
Future<String?> promptVoidReason(String title) async {
  final controller = TextEditingController();
  final reason = await Get.dialog<String>(
    AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'receivable_void_reason_label'.tr,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text('common_cancel'.tr),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) Get.back(result: text);
          },
          child: Text('receivable_void_confirm_button'.tr),
        ),
      ],
    ),
  );
  controller.dispose();
  return reason;
}
