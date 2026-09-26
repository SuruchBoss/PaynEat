// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/checkout_controller.dart';

/// QR พร้อมเพย์จริงสำหรับช่องทางจ่าย "qr" (ดู docs/tickets/16-promptpay-qr.md) — เรนเดอร์
/// payload ที่ backend/demo store คำนวณมาให้เป็นภาพ QR ตรง ๆ ไม่มีการตรวจสอบการจ่ายอัตโนมัติ
/// แคชเชียร์ต้องเช็คสลิป/แอปธนาคารเองว่าลูกค้าโอนมาจริงก่อนกดยืนยัน (เหมือนช่องทางโอน/บัตร)
class PromptPayQrView extends GetView<CheckoutController> {
  const PromptPayQrView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final qr = controller.promptPayQr.value;
      final error = controller.promptPayQrError.value;
      final isLoading = controller.isLoadingQr.value;

      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (isLoading && qr == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (error != null)
              _QrError(message: error)
            else if (qr != null)
              Column(
                children: [
                  ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(
                        data: qr.payload,
                        size: 200,
                        backgroundColor: Colors.white,
                        semanticsLabel: 'payment_promptpay_qr_semantics'.tr,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'payment_promptpay_scan_instruction'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'payment_promptpay_amount_required'.tr,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _QrError extends StatelessWidget {
  const _QrError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.error_outline_rounded, color: AppColors.dangerInk, size: 28),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.dangerInk),
        ),
      ],
    );
  }
}
