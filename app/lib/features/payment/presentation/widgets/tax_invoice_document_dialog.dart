import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../tax_invoice/domain/entities/tax_invoice.dart';

/// แสดงใบกำกับภาษีที่ออกแล้ว ครบตามข้อมูลที่กฎหมายกำหนด (ดู docs/DECISIONS.md #16):
/// อย่างย่อแสดงราคารวม VAT พร้อมข้อความกำกับ, เต็มรูปแยกยอด VAT ออกจากราคาสินค้าชัดเจน
/// และมีชื่อ+ที่อยู่ผู้ซื้อ — คืนค่าเป็นเหตุผลยกเลิกถ้าผู้ใช้กดยกเลิกใบนี้ (null ถ้าแค่ปิดดู)
class TaxInvoiceDocumentDialog extends StatelessWidget {
  const TaxInvoiceDocumentDialog({
    super.key,
    required this.invoice,
    required this.canVoid,
  });

  final TaxInvoice invoice;
  final bool canVoid;

  static Future<String?> show({
    required TaxInvoice invoice,
    required bool canVoid,
  }) {
    return Get.dialog<String>(
      TaxInvoiceDocumentDialog(invoice: invoice, canVoid: canVoid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFull = invoice.isFull;
    return AlertDialog(
      title: Text(
        isFull
            ? 'tax_invoice_document_title_full'.tr
            : 'tax_invoice_document_title_abbreviated'.tr,
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (invoice.isVoid) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'tax_invoice_voided_badge'.tr,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (invoice.voidReason != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          invoice.voidReason!,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _Row(
                label: 'tax_invoice_running_number_label'.tr,
                value: invoice.runningNumber,
                bold: true,
              ),
              _Row(
                label: 'tax_invoice_issued_at_label'.tr,
                value: Formatters.dateTime(invoice.issuedAt),
              ),
              if (invoice.orderCode != null)
                _Row(
                  label: 'tax_invoice_order_code_label'.tr,
                  value: invoice.orderCode!,
                ),
              const Divider(height: 20),
              Text(
                'tax_invoice_store_section_title'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(invoice.storeName, style: const TextStyle(fontSize: 13)),
              Text(
                invoice.storeAddress,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'tax_invoice_tax_id_value'.trParams({
                  'taxId': invoice.storeTaxId,
                }),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (invoice.storeBranch != null)
                Text(
                  invoice.storeBranch!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (isFull) ...[
                const Divider(height: 20),
                Text(
                  'tax_invoice_customer_section_title'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  invoice.customerName ?? '',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  invoice.customerAddress ?? '',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (invoice.customerTaxId != null)
                  Text(
                    'tax_invoice_tax_id_value'.trParams({
                      'taxId': invoice.customerTaxId!,
                    }),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
              const Divider(height: 20),
              if (isFull) ...[
                _Row(
                  label: 'tax_invoice_subtotal_label'.tr,
                  value: Formatters.money(invoice.subtotal),
                ),
                _Row(
                  label: 'tax_invoice_vat_label'.tr,
                  value: Formatters.money(invoice.vat),
                ),
                _Row(
                  label: 'tax_invoice_total_label'.tr,
                  value: Formatters.baht(invoice.total),
                  bold: true,
                ),
              ] else ...[
                _Row(
                  label: 'tax_invoice_total_vat_included_label'.tr,
                  value: Formatters.baht(invoice.total),
                  bold: true,
                ),
              ],
              if (invoice.issuedByName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'tax_invoice_issued_by_label'.trParams({
                    'name': invoice.issuedByName!,
                  }),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (canVoid && !invoice.isVoid)
          TextButton(
            onPressed: () => _promptVoid(context),
            child: Text(
              'tax_invoice_void_button'.tr,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        FilledButton(
          onPressed: () => Get.back<String>(),
          child: Text('common_close'.tr),
        ),
      ],
    );
  }

  Future<void> _promptVoid(BuildContext context) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('tax_invoice_void_confirm_title'.tr),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'tax_invoice_void_reason_label'.tr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common_cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(dialogContext).pop(reason);
            },
            child: Text('tax_invoice_void_confirm_button'.tr),
          ),
        ],
      ),
    );
    if (reason != null) Get.back<String>(result: reason);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 14 : 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
