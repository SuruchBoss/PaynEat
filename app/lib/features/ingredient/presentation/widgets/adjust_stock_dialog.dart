import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/ingredient.dart';

/// ผลลัพธ์จากกล่องปรับสต๊อก — [delta] เป็นบวก (รับเข้า) หรือลบ (ตัดออก/เสียหาย) ก็ได้
class AdjustStockResult {
  const AdjustStockResult({required this.delta});

  final double delta;
}

/// กล่องปรับสต๊อกวัตถุดิบด้วยมือ — ใช้ตอนรับของเข้า หรือตัดออกเพราะของเสีย
class AdjustStockDialog extends StatefulWidget {
  const AdjustStockDialog({super.key, required this.ingredient});

  final Ingredient ingredient;

  static Future<AdjustStockResult?> show(Ingredient ingredient) {
    return Get.dialog<AdjustStockResult>(
      AdjustStockDialog(ingredient: ingredient),
    );
  }

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  bool _isReceiving = true;
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final ingredient = widget.ingredient;
    return AlertDialog(
      title: Text(
        'ingredient_adjust_stock_title'.trParams({'name': ingredient.name}),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ingredient_current_stock_label'.trParams({
              'stock': ingredient.currentStock.toStringAsFixed(1),
              'unit': ingredient.unit,
            }),
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text('ingredient_receive_stock_option'.tr),
              ),
              ButtonSegment(
                value: false,
                label: Text('ingredient_deduct_stock_option'.tr),
              ),
            ],
            selected: {_isReceiving},
            onSelectionChanged: (values) =>
                setState(() => _isReceiving = values.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: 'ingredient_adjust_amount_label'.tr,
              suffixText: ingredient.unit,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text(
            'common_close'.tr,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: _amount > 0
              ? () => Get.back(
                  result: AdjustStockResult(
                    delta: _isReceiving ? _amount : -_amount,
                  ),
                )
              : null,
          child: Text('ingredient_adjust_apply_button'.tr),
        ),
      ],
    );
  }
}
