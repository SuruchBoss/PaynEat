import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/utils/formatters.dart';

/// ผลลัพธ์จากกล่องคืนเงิน
class RefundResult {
  const RefundResult({required this.amount, required this.reason});

  final double amount;
  final String reason;
}

/// กล่องคืนเงิน — จำกัดยอดไม่ให้เกินยอดที่คืนได้ของ payment นั้น และบังคับกรอกเหตุผลเสมอ
/// (เก็บ audit trail ว่าใครคืนให้ใครเพราะอะไร)
class RefundDialog extends StatefulWidget {
  const RefundDialog({super.key, required this.maxAmount});

  final double maxAmount;

  static Future<RefundResult?> show({required double maxAmount}) {
    return Get.dialog<RefundResult>(RefundDialog(maxAmount: maxAmount));
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

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final reason = _reasonController.text.trim();

    if (amount <= 0 || amount > widget.maxAmount + 0.001) {
      setState(
        () => _error =
            'ยอดคืนต้องมากกว่า 0 และไม่เกิน ${Formatters.baht(widget.maxAmount)}',
      );
      return;
    }
    if (reason.isEmpty) {
      setState(() => _error = 'กรุณาระบุเหตุผลที่คืนเงิน');
      return;
    }

    Get.back(
      result: RefundResult(amount: amount, reason: reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('คืนเงิน'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('คืนได้สูงสุด ${Formatters.baht(widget.maxAmount)}'),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'ยอดที่คืน',
              suffixText: 'บาท',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'เหตุผลที่คืนเงิน',
              hintText: 'เช่น ลูกค้าคืนอาหาร / เก็บเงินผิด',
            ),
          ),
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
          child: const Text('ยกเลิก'),
        ),
        FilledButton(onPressed: _submit, child: const Text('ยืนยันคืนเงิน')),
      ],
    );
  }
}
