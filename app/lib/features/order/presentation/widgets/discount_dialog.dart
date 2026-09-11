import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// ผลลัพธ์จากกล่องใส่ส่วนลด
class DiscountResult {
  const DiscountResult({required this.type, required this.value});

  final String type;
  final double value;
}

/// กล่องใส่ส่วนลด — เลือกได้ทั้งแบบบาทและเปอร์เซ็นต์ พร้อมปุ่มลัดที่ร้านใช้บ่อย
class DiscountDialog extends StatefulWidget {
  const DiscountDialog({super.key, this.currentType = DiscountType.none});

  final String currentType;

  static Future<DiscountResult?> show({
    String currentType = DiscountType.none,
  }) {
    return Get.dialog<DiscountResult>(DiscountDialog(currentType: currentType));
  }

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  late String _type = widget.currentType == DiscountType.none
      ? DiscountType.percent
      : widget.currentType;
  final TextEditingController _valueController = TextEditingController();

  static const List<double> _percentShortcuts = [5, 10, 15, 20];

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_valueController.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('order_discount_title'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: DiscountType.percent,
                label: Text('order_discount_percent_option'.tr),
              ),
              ButtonSegment(
                value: DiscountType.amount,
                label: Text('order_discount_amount_option'.tr),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (values) =>
                setState(() => _type = values.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: _type == DiscountType.percent
                  ? 'order_discount_percent_hint'.tr
                  : 'order_discount_amount_hint'.tr,
              suffixText: _type == DiscountType.percent
                  ? '%'
                  : 'common_baht'.tr,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_type == DiscountType.percent) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _percentShortcuts
                  .map(
                    (percent) => ActionChip(
                      label: Text('${percent.toStringAsFixed(0)}%'),
                      onPressed: () => setState(
                        () =>
                            _valueController.text = percent.toStringAsFixed(0),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
      actions: [
        if (widget.currentType != DiscountType.none)
          TextButton(
            onPressed: () => Get.back(
              result: const DiscountResult(type: DiscountType.none, value: 0),
            ),
            child: Text(
              'order_discount_remove_button'.tr,
              style: const TextStyle(color: AppColors.dangerInk),
            ),
          ),
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text(
            'common_close'.tr,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: _value > 0
              ? () => Get.back(
                  result: DiscountResult(type: _type, value: _value),
                )
              : null,
          child: Text('order_discount_apply_button'.tr),
        ),
      ],
    );
  }
}
