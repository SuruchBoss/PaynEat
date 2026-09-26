// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/receivable.dart';

/// ค่าที่กรอกตอนออกใบลดหนี้
class CreditNoteInput {
  const CreditNoteInput({
    required this.paymentId,
    required this.amount,
    required this.reason,
  });

  final int paymentId;
  final double amount;
  final String reason;
}

/// ลดหนี้บิลขายเชื่อ + ออกใบลดหนี้ (ดู docs/tickets/21-late-fees-credit-notes.md) — เลือกบิลที่ยังค้าง
/// ลดได้ไม่เกินเงินต้นที่ยังค้าง (ยอดบิล − ที่ลดไปแล้ว และไม่เกินยอดค้าง) เหตุผลบังคับกรอกเพราะพิมพ์ลง
/// ใบลดหนี้และ audit log
class CreditNoteDialog extends StatefulWidget {
  const CreditNoteDialog({super.key, required this.invoices});

  /// บิลขายเชื่อที่ยังค้าง
  final List<CreditInvoice> invoices;

  static Future<CreditNoteInput?> show(List<CreditInvoice> invoices) =>
      Get.dialog<CreditNoteInput>(CreditNoteDialog(invoices: invoices));

  /// ลดหนี้ได้สูงสุดเท่าไรสำหรับบิลนี้ — ตรงกับกฎของ payment.service.js#refund
  static double maxCredit(CreditInvoice invoice) {
    final principal = invoice.amount - invoice.refunded;
    final value = principal < invoice.outstanding
        ? principal
        : invoice.outstanding;
    return value < 0 ? 0 : (value * 100).round() / 100;
  }

  @override
  State<CreditNoteDialog> createState() => _CreditNoteDialogState();
}

class _CreditNoteDialogState extends State<CreditNoteDialog> {
  late CreditInvoice _invoice = widget.invoices.first;
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  double get _max => CreditNoteDialog.maxCredit(_invoice);

  double? get _amountValue {
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0 || value > _max + 0.001) return null;
    return value;
  }

  bool get _isValid => _amountValue != null && _reason.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('receivable_credit_note_dialog_title'.tr),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                key: const ValueKey('credit-note-invoice'),
                initialValue: _invoice.paymentId,
                isExpanded: true,
                // "#ORD-20260728-0001 (ค้าง 6,167.48)" บรรทัดเดียวยาวเกินช่องบนมือถือทุกภาษา ถูกตัดเหลือ
                // "#ORD-20260728-0001 (…" — ในรายการแยกเป็นสองบรรทัด ส่วนช่องที่เลือกแล้วโชว์แค่เลขบิล
                // (ยอดค้างสูงสุดมีบอกใต้ช่องยอดลดหนี้อยู่แล้ว)
                itemHeight: null,
                decoration: InputDecoration(
                  labelText: 'receivable_credit_note_invoice_label'.tr,
                ),
                selectedItemBuilder: (context) => [
                  for (final invoice in widget.invoices)
                    Text(
                      '#${invoice.orderCode}',
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
                items: [
                  for (final invoice in widget.invoices)
                    DropdownMenuItem(
                      value: invoice.paymentId,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${invoice.orderCode}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'receivable_credit_note_invoice_owes'.trParams({
                                'amount': Formatters.baht(invoice.outstanding),
                              }),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                onChanged: (paymentId) => setState(
                  () => _invoice = widget.invoices.firstWhere(
                    (invoice) => invoice.paymentId == paymentId,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('credit-note-amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'receivable_credit_note_amount_label'.tr,
                  suffixText: 'common_baht'.tr,
                  helperText: 'receivable_credit_note_max'.trParams({
                    'amount': Formatters.baht(_max),
                  }),
                  errorText: _amount.text.isNotEmpty && _amountValue == null
                      ? 'receivable_credit_note_amount_invalid'.tr
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('credit-note-reason'),
                controller: _reason,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: 'receivable_credit_note_reason_label'.tr,
                  hintText: 'receivable_credit_note_reason_hint'.tr,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text('common_cancel'.tr),
        ),
        FilledButton(
          key: const ValueKey('credit-note-confirm'),
          onPressed: _isValid
              ? () => Get.back(
                  result: CreditNoteInput(
                    paymentId: _invoice.paymentId,
                    amount: _amountValue!,
                    reason: _reason.text.trim(),
                  ),
                )
              : null,
          child: Text('receivable_credit_note_issue'.tr),
        ),
      ],
    );
  }
}
