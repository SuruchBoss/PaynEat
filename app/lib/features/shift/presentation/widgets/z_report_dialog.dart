import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../report/domain/entities/report.dart';
import '../controllers/shift_controller.dart';

/// แสดงสรุปปิดกะ (Z-report) — ยอดขาย/ภาษี/ส่วนลด/ช่องทางชำระเงิน พร้อมกระทบยอดเงินสด
/// (ดู docs/tickets/12-report-export.md, docs/tickets/01-shift-cash-reconciliation.md)
///
/// เรียกผ่าน [show] แทนสร้างตรง ๆ เพราะต้องรอโหลดข้อมูลจาก [ShiftController.loadZReport] ก่อน
class ZReportDialog extends StatelessWidget {
  const ZReportDialog({super.key, required this.shiftId, required this.report});

  final int shiftId;
  final ZReport report;

  static Future<void> show(int shiftId) async {
    final controller = Get.find<ShiftController>();
    final report = await controller.loadZReport(shiftId);
    if (report == null) return;
    await Get.dialog(ZReportDialog(shiftId: shiftId, report: report));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'shift_z_report_title'.tr,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _row('report_order_count_label'.tr, '${report.orderCount}'),
                    _row(
                      'shift_z_report_guest_count_label'.tr,
                      '${report.guestCount}',
                    ),
                    const Divider(height: 22),
                    _row(
                      'report_subtotal_label'.tr,
                      Formatters.baht(report.subtotal),
                    ),
                    _row(
                      'shift_z_report_discount_label'.tr,
                      Formatters.baht(report.discount),
                    ),
                    _row(
                      'shift_z_report_promotion_discount_label'.tr,
                      Formatters.baht(report.promotionDiscount),
                    ),
                    _row(
                      'shift_z_report_total_discount_label'.tr,
                      Formatters.baht(report.totalDiscount),
                      emphasize: true,
                    ),
                    _row(
                      'shift_z_report_service_charge_label'.tr,
                      Formatters.baht(report.serviceCharge),
                    ),
                    _row(
                      'shift_z_report_vat_label'.tr,
                      Formatters.baht(report.vat),
                    ),
                    _row(
                      'shift_z_report_refund_label'.tr,
                      Formatters.baht(report.refundTotal),
                    ),
                    const Divider(height: 22),
                    _row(
                      'report_net_sales_label'.tr,
                      Formatters.baht(report.netSales),
                      emphasize: true,
                    ),
                    if (report.paymentMethods.isNotEmpty) ...[
                      const Divider(height: 22),
                      Text(
                        'report_payment_methods_title'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final method in report.paymentMethods)
                        _row(
                          '${method.label} (${method.count})',
                          Formatters.baht(method.amount),
                        ),
                    ],
                    // รับชำระหนี้ลูกค้าเครดิต — ไม่ใช่ยอดขายของกะนี้ แต่เงินสดส่วนนี้อยู่ในลิ้นชัก
                    // ต้องเห็นว่าเงินสดที่คาดไว้มาจากไหน (ดู docs/DECISIONS.md #50)
                    if (report.receivableReceipts.isNotEmpty) ...[
                      const Divider(height: 22),
                      Text(
                        'shift_z_report_receivables_title'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final method in report.receivableReceipts)
                        _row(
                          '${method.label} (${method.count})',
                          Formatters.baht(method.amount),
                        ),
                    ],
                    if (report.isShiftReport) ...[
                      const Divider(height: 22),
                      Text(
                        'shift_z_report_cash_reconciliation_title'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _row(
                        'shift_starting_cash_label'.tr,
                        Formatters.baht(report.openingCash ?? 0),
                      ),
                      _row(
                        'shift_expected_cash_label'.tr,
                        Formatters.baht(report.expectedCash ?? 0),
                      ),
                      _row(
                        'shift_counted_cash_label'.tr,
                        Formatters.baht(report.countedCash ?? 0),
                      ),
                      _row(
                        'shift_z_report_variance_label'.tr,
                        Formatters.baht((report.variance ?? 0).abs()),
                        emphasize: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Obx(() {
                final controller = Get.find<ShiftController>();
                return FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: controller.isExportingZReport.value
                      ? null
                      : () => controller.exportZReportCsv(shiftId),
                  icon: controller.isExportingZReport.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surface,
                          ),
                        )
                      : const Icon(Icons.file_download_rounded),
                  label: Text('shift_z_report_export_button'.tr),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                color: emphasize ? null : AppColors.textSecondary,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
