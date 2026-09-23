import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../domain/entities/receivable.dart';
import 'void_reason_prompt.dart';

/// แสดงใบวางบิล/ใบเสร็จรับชำระหนี้แบบเอกสาร — หัวร้าน, ลูกค้า (ชื่อ/เลขผู้เสียภาษี/ที่อยู่),
/// รายการบิลที่อ้างถึง และยอดรวม คืนเหตุผลยกเลิกถ้าผู้จัดการกดยกเลิกเอกสารนี้ (null = แค่ปิดดู)
/// (ดู docs/tickets/20-b2b-credit.md)
class ReceivableDocumentDialog extends StatelessWidget {
  const ReceivableDocumentDialog._({
    required this.title,
    required this.number,
    required this.issuedAt,
    required this.store,
    required this.customer,
    required this.customerName,
    required this.lines,
    required this.totalLabel,
    required this.total,
    required this.isVoided,
    required this.canVoid,
    required this.voidTitle,
    this.voidReason,
    this.extraRows = const [],
    this.footer,
  });

  final String title;
  final String number;
  final String? issuedAt;
  final DocumentStoreInfo? store;
  final Customer? customer;
  final String customerName;
  final List<DocumentLine> lines;
  final String totalLabel;
  final double total;
  final bool isVoided;
  final String? voidReason;
  final bool canVoid;
  final String voidTitle;
  final List<(String, String)> extraRows;
  final String? footer;

  static Future<String?> showBillingNote(
    BillingNote note, {
    required bool canVoid,
  }) => Get.dialog<String>(
    ReceivableDocumentDialog._(
      title: 'receivable_billing_note_title'.tr,
      number: note.noteNo,
      issuedAt: note.issuedAt,
      store: note.store,
      customer: note.customer,
      customerName: note.customerName,
      lines: note.items,
      totalLabel: 'receivable_billing_note_total'.tr,
      total: note.total,
      isVoided: note.isVoided,
      voidReason: note.voidReason,
      canVoid: canVoid,
      voidTitle: 'receivable_billing_note_void_title'.tr,
      extraRows: [
        (
          'receivable_billing_note_due_date'.tr,
          Formatters.dueDate(note.dueDate),
        ),
        if (!note.isVoided)
          (
            'receivable_billing_note_remaining'.tr,
            Formatters.baht(note.remaining),
          ),
      ],
      footer: note.issuedByName == null
          ? null
          : 'receivable_document_issued_by'.trParams({
              'name': note.issuedByName!,
            }),
    ),
  );

  static Future<String?> showReceipt(
    ArReceipt receipt, {
    required bool canVoid,
  }) => Get.dialog<String>(
    ReceivableDocumentDialog._(
      title: 'receivable_receipt_title'.tr,
      number: receipt.receiptNo,
      issuedAt: receipt.receivedAt,
      store: receipt.store,
      customer: receipt.customer,
      customerName: receipt.customerName,
      lines: receipt.allocations,
      totalLabel: 'receivable_receipt_total'.tr,
      total: receipt.amount,
      isVoided: receipt.isVoided,
      voidReason: receipt.voidReason,
      canVoid: canVoid,
      voidTitle: 'receivable_receipt_void_title'.tr,
      extraRows: [
        ('receivable_receipt_method'.tr, PaymentMethod.label(receipt.method)),
        if (receipt.reference != null && receipt.reference!.isNotEmpty)
          ('receivable_receipt_reference'.tr, receipt.reference!),
      ],
      footer: receipt.receivedByName == null
          ? null
          : 'receivable_document_received_by'.trParams({
              'name': receipt.receivedByName!,
            }),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final secondary = TextStyle(fontSize: 12.5, color: AppColors.textSecondary);
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isVoided) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    voidReason == null
                        ? 'receivable_document_voided'.tr
                        : '${'receivable_document_voided'.tr} — $voidReason',
                    style: TextStyle(
                      color: AppColors.dangerInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _Row(
                label: 'receivable_document_no'.tr,
                value: number,
                bold: true,
              ),
              _Row(
                label: 'receivable_document_date'.tr,
                value: Formatters.dateTime(issuedAt),
              ),
              for (final (label, value) in extraRows)
                _Row(label: label, value: value),
              if (store != null) ...[
                const Divider(height: 20),
                Text(
                  store!.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (store!.address != null)
                  Text(store!.address!, style: secondary),
                if (store!.taxId != null)
                  Text(
                    'tax_invoice_tax_id_value'.trParams({
                      'taxId': store!.taxId!,
                    }),
                    style: secondary,
                  ),
              ],
              const Divider(height: 20),
              Text(
                'receivable_document_customer'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(customerName, style: const TextStyle(fontSize: 13)),
              if (customer?.address != null)
                Text(customer!.address!, style: secondary),
              if (customer?.taxId != null)
                Text(
                  'tax_invoice_tax_id_value'.trParams({
                    'taxId': customer!.taxId!,
                  }),
                  style: secondary,
                ),
              const Divider(height: 20),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${line.orderCode}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'receivable_line_dates'.trParams({
                                'date': Formatters.dateTime(line.createdAt),
                                'due': Formatters.dueDate(line.dueDate),
                              }),
                              style: secondary,
                            ),
                          ],
                        ),
                      ),
                      Text(Formatters.money(line.amount)),
                    ],
                  ),
                ),
              const Divider(height: 20),
              _Row(
                label: totalLabel,
                value: Formatters.baht(total),
                bold: true,
              ),
              if (footer != null) ...[
                const SizedBox(height: 8),
                Text(
                  footer!,
                  style: TextStyle(
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
        if (canVoid && !isVoided)
          TextButton(
            onPressed: () async {
              final reason = await promptVoidReason(voidTitle);
              if (reason != null) Get.back<String>(result: reason);
            },
            child: Text(
              'receivable_void_button'.tr,
              style: TextStyle(color: AppColors.dangerInk),
            ),
          ),
        FilledButton(
          onPressed: () => Get.back<String>(),
          child: Text('common_close'.tr),
        ),
      ],
    );
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
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: bold ? 14 : 12.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
