// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/usecases/result.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/payment.dart';

/// ผลลัพธ์จากกล่องคืนเงิน
class RefundResult {
  const RefundResult({required this.amount, required this.reason});

  final double amount;
  final String reason;
}

/// กล่องคืนเงิน — จำกัดยอดไม่ให้เกินยอดที่คืนได้ของ payment นั้น และบังคับกรอกเหตุผลเสมอ
/// (เก็บ audit trail ว่าใครคืนให้ใครเพราะอะไร)
///
/// payment ที่ลูกค้าใช้แต้มจ่ายส่ง [preview] มาด้วย: กดยืนยันครั้งแรกจะถามระบบก่อนว่ายอดนี้แบ่งเป็นเงินกี่บาทกับแต้มกี่แต้ม
/// แล้วแสดงให้ดู ต้องกดยืนยันอีกครั้งจึงคืนจริง (T11 #101, docs/DECISIONS.md #77 D7, #99) แก้ยอดเมื่อไหร่ต้องดูตัวอย่างใหม่
class RefundDialog extends StatefulWidget {
  const RefundDialog({super.key, required this.maxAmount, this.preview});

  final double maxAmount;
  final Future<Result<RefundPreview>> Function(double amount)? preview;

  static Future<RefundResult?> show({
    required double maxAmount,
    Future<Result<RefundPreview>> Function(double amount)? preview,
  }) {
    return Get.dialog<RefundResult>(
      RefundDialog(maxAmount: maxAmount, preview: preview),
    );
  }

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  late final TextEditingController _amountController = TextEditingController(
    text: widget.maxAmount.toStringAsFixed(2),
  );
  final TextEditingController _reasonController = TextEditingController();
  String? _error;
  RefundPreview? _shown;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_clearPreviewIfAmountChanged);
  }

  void _clearPreviewIfAmountChanged() {
    final shown = _shown;
    if (shown == null) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if ((amount - shown.amount).abs() > 0.001) setState(() => _shown = null);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final reason = _reasonController.text.trim();

    if (amount <= 0 || amount > widget.maxAmount + 0.001) {
      setState(
        () => _error = 'payment_refund_amount_invalid'.trParams({
          'amount': Formatters.baht(widget.maxAmount),
        }),
      );
      return;
    }
    if (reason.isEmpty) {
      setState(() => _error = 'payment_refund_reason_required'.tr);
      return;
    }

    final preview = widget.preview;
    if (preview != null && _shown == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
      final result = await preview(amount);
      if (!mounted) return;
      result.fold(
        onSuccess: (split) => setState(() {
          _loading = false;
          _shown = split;
        }),
        onFailure: (failure) => setState(() {
          _loading = false;
          _error = failure.message;
        }),
      );
      return;
    }

    Get.back(
      result: RefundResult(amount: amount, reason: reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('payment_refund_dialog_title'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'payment_refund_max_amount_label'.trParams({
              'amount': Formatters.baht(widget.maxAmount),
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: 'payment_refund_amount_label'.tr,
              suffixText: 'common_baht'.tr,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: 'payment_refund_reason_label'.tr,
              hintText: 'payment_refund_reason_hint'.tr,
            ),
          ),
          if (_shown != null) ...[
            const SizedBox(height: 12),
            Text(
              'payment_refund_split_preview'.trParams({
                'cash': Formatters.baht(_shown!.cashAmount),
                'points': '${_shown!.pointsReturned}',
                'value': Formatters.baht(_shown!.pointsValue),
              }),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text('payment_refund_split_confirm_hint'.tr),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text('common_cancel'.tr),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: Text(
            widget.preview != null && _shown == null
                ? 'payment_refund_split_check_button'.tr
                : 'payment_confirm_refund_button'.tr,
          ),
        ),
      ],
    );
  }
}
