import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/dining_table.dart';
import '../controllers/table_controller.dart';

/// QR สั่งอาหารเองของโต๊ะหนึ่ง ๆ (ดู docs/tickets/17-qr-self-order.md) — เข้ารหัสลิงก์ที่ชี้ไปหน้า
/// self-order สาธารณะ (ไม่มี login) ให้ลูกค้าสแกนจากมือถือตัวเอง ปุ่ม "เปลี่ยน QR" มีไว้ปิดลิงก์เก่า
/// ทันทีถ้า QR ที่พิมพ์ไว้ที่โต๊ะหลุด/ถูกถ่ายรูปแอบอ้างไป
class TableQrView extends GetView<TableController> {
  const TableQrView({required this.table, super.key});

  final DiningTable table;

  @override
  Widget build(BuildContext context) {
    // ผูกกับ controller.tables แทนใช้ตัวแปร table ตรงๆ เพราะกด "เปลี่ยน QR" แล้วต้องเห็นภาพ QR
    // ใหม่ทันทีในชีทเดิม ไม่ต้องปิดแล้วเปิดใหม่
    return Obx(() {
      final current = controller.tables.firstWhere(
        (row) => row.id == table.id,
        orElse: () => table,
      );
      final qrToken = current.qrToken;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'table_qr_sheet_title'.trParams({'name': current.name}),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (qrToken == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'table_qr_missing_message'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            _QrContent(table: current, qrToken: qrToken),
        ],
      );
    });
  }
}

class _QrContent extends GetView<TableController> {
  const _QrContent({required this.table, required this.qrToken});

  final DiningTable table;
  final String qrToken;

  @override
  Widget build(BuildContext context) {
    final link = AppConfig.selfOrderLink(qrToken);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: QrImageView(
                data: link,
                size: 200,
                backgroundColor: Colors.white,
                semanticsLabel: 'table_qr_semantics'.trParams({
                  'name': table.name,
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'table_qr_scan_instruction'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: link));
            AppDialogs.success('table_qr_link_copied'.tr);
          },
          icon: const Icon(Icons.link_rounded, size: 18),
          label: Text('table_qr_copy_link_button'.tr),
        ),
        if (controller.canManageQrToken) ...[
          const SizedBox(height: 8),
          Obx(
            () => TextButton.icon(
              onPressed: controller.isRegeneratingQr.value
                  ? null
                  : () => controller.regenerateQrToken(table),
              icon: controller.isRegeneratingQr.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.dangerInk,
                    ),
              label: Text(
                'table_qr_regenerate_button'.tr,
                style: TextStyle(color: AppColors.dangerInk),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
