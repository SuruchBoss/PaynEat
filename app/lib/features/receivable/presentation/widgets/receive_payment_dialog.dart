import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/receivable.dart';

/// ค่าที่กรอกในกล่องรับชำระหนี้
class ReceivePaymentInput {
  const ReceivePaymentInput({
    required this.amount,
    required this.method,
    this.reference,
    this.billingNoteId,
  });

  final double amount;
  final String method;
  final String? reference;
  final int? billingNoteId;
}

/// กล่องรับชำระหนี้ (ดู docs/tickets/20-b2b-credit.md) — ค่าเริ่มต้นคือยอดค้างทั้งหมด เลือกรับตาม
/// ใบวางบิลที่ลูกค้าถือมาได้ (ยอดเปลี่ยนเป็นยอดคงเหลือของใบนั้น) รับเกินยอดค้างไม่ได้
class ReceivePaymentDialog extends StatefulWidget {
  const ReceivePaymentDialog({super.key, required this.statement});

  final CustomerStatement statement;

  static Future<ReceivePaymentInput?> show(CustomerStatement statement) =>
      Get.dialog<ReceivePaymentInput>(
        ReceivePaymentDialog(statement: statement),
      );

  @override
  State<ReceivePaymentDialog> createState() => _ReceivePaymentDialogState();
}

class _ReceivePaymentDialogState extends State<ReceivePaymentDialog> {
  late final TextEditingController _amountController = TextEditingController(
    text: widget.statement.summary.outstanding.toStringAsFixed(2),
  );
  final TextEditingController _referenceController = TextEditingController();
  String _method = PaymentMethod.transfer;
  int? _billingNoteId;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  double get _maxAmount {
    final noteId = _billingNoteId;
    if (noteId == null) return widget.statement.summary.outstanding;
    return widget.statement.billingNotes
        .firstWhere((note) => note.id == noteId)
        .remaining;
  }

  double? get _amount => double.tryParse(_amountController.text.trim());

  bool get _isValid {
    final amount = _amount;
    return amount != null && amount > 0 && amount <= _maxAmount + 0.001;
  }

  void _selectNote(int? noteId) {
    setState(() {
      _billingNoteId = noteId;
      _amountController.text = _maxAmount.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final openNotes = widget.statement.openBillingNotes;
    return AlertDialog(
      title: Text('receivable_receive_title'.tr),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'receivable_receive_outstanding'.trParams({
                  'amount': Formatters.baht(
                    widget.statement.summary.outstanding,
                  ),
                }),
                style: TextStyle(color: AppColors.textSecondary),
              ),
              if (openNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  // isExpanded ให้รายการตัดท้ายด้วย … แทนที่จะล้นกล่องบนจอมือถือแคบ ๆ
                  isExpanded: true,
                  initialValue: _billingNoteId,
                  decoration: InputDecoration(
                    labelText: 'receivable_receive_against_note'.tr,
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      child: Text(
                        'receivable_receive_oldest_first'.tr,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (final note in openNotes)
                      DropdownMenuItem<int?>(
                        value: note.id,
                        child: Text(
                          '${note.noteNo} · ${Formatters.baht(note.remaining)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _selectNote,
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('receive-amount'),
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'receivable_receive_amount_label'.tr,
                  suffixText: 'common_baht'.tr,
                  errorText: _amountController.text.isNotEmpty && !_isValid
                      ? 'receivable_receive_amount_invalid'.trParams({
                          'max': Formatters.money(_maxAmount),
                        })
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final method in PaymentMethod.all)
                    ChoiceChip(
                      label: Text(PaymentMethod.label(method)),
                      selected: _method == method,
                      onSelected: (_) => setState(() => _method = method),
                    ),
                ],
              ),
              if (_method == PaymentMethod.cash)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'receivable_receive_cash_hint'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _referenceController,
                decoration: InputDecoration(
                  labelText: 'receivable_receive_reference_label'.tr,
                ),
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
          onPressed: _isValid
              ? () => Get.back(
                  result: ReceivePaymentInput(
                    amount: _amount!,
                    method: _method,
                    reference: _referenceController.text.trim(),
                    billingNoteId: _billingNoteId,
                  ),
                )
              : null,
          child: Text('receivable_receive_confirm'.tr),
        ),
      ],
    );
  }
}
