import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/domain/entities/menu_option.dart';
import '../../../scale/presentation/widgets/live_scale_panel.dart';
import '../../domain/entities/cart_line.dart';

/// กรอกน้ำหนักที่ชั่งได้ของสินค้าขายตามน้ำหนัก (ดู docs/tickets/18-sell-by-weight.md)
///
/// กรอกเป็นกิโลกรัมตามที่หน้าจอตาชั่งแสดง (เช่น 0.485) แล้วแปลงเป็นกรัมเต็มก่อนส่ง — ราคาที่โชว์
/// ใต้ช่องคิดด้วย [CartLine.lineTotal] ตัวเดียวกับตะกร้า จึงตรงกับที่ backend คิดทุกสตางค์
/// ใช้ทั้งตอนใส่ตะกร้าครั้งแรกและตอน "ชั่งใหม่" บรรทัดที่อยู่ในตะกร้าแล้ว
///
/// ร้านที่ต่อตาชั่งเข้าเซิร์ฟเวอร์ (ticket 22) เห็นน้ำหนักสดด้านบน กด "ใช้น้ำหนักนี้" ได้ทันทีไม่ต้องพิมพ์
class WeightEntryDialog extends StatefulWidget {
  const WeightEntryDialog({
    super.key,
    required this.item,
    this.options = const [],
    this.initialGrams,
  });

  final MenuItem item;

  /// ตัวเลือกที่เลือกไว้แล้ว (เช่น หมักซอส +40/กก.) — ใช้คิดราคาตัวอย่างให้ตรงกับบรรทัดจริง
  final List<MenuOption> options;
  final int? initialGrams;

  /// เปิดกล่องแล้วคืนน้ำหนักเป็นกรัม (null = ยกเลิก)
  static Future<int?> show(
    MenuItem item, {
    List<MenuOption> options = const [],
    int? initialGrams,
  }) => Get.dialog<int>(
    WeightEntryDialog(item: item, options: options, initialGrams: initialGrams),
  );

  /// แปลงข้อความกิโลกรัมเป็นกรัม — null ถ้าอ่านไม่ได้หรืออยู่นอกช่วงที่ backend รับ (1–99,999 กรัม)
  static int? parseGrams(String text) {
    final kg = double.tryParse(text.trim().replaceAll(',', '.'));
    if (kg == null) return null;
    final grams = (kg * 1000).round();
    return grams >= 1 && grams <= 99999 ? grams : null;
  }

  @override
  State<WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends State<WeightEntryDialog> {
  late final TextEditingController _kgController = TextEditingController(
    text: widget.initialGrams == null
        ? ''
        : (widget.initialGrams! / 1000).toStringAsFixed(3),
  );
  final FocusNode _kgFocus = FocusNode();

  @override
  void dispose() {
    _kgController.dispose();
    _kgFocus.dispose();
    super.dispose();
  }

  CartLine _lineFor(int? grams) => CartLine(
    menuItem: widget.item,
    weightGrams: grams,
    selectedOptions: widget.options,
  );

  int? get _grams => WeightEntryDialog.parseGrams(_kgController.text);

  void _submit() {
    final grams = _grams;
    if (grams != null) Get.back(result: grams);
  }

  @override
  Widget build(BuildContext context) {
    final grams = _grams;
    final line = _lineFor(grams);
    final preview = grams == null ? null : line.lineTotal;

    return AlertDialog(
      // แผงน้ำหนักสด + ช่องกรอก สูงเกินจอมือถือแนวนอนได้ — เลื่อนได้แทนล้นจอ
      scrollable: true,
      title: Text(
        'order_weigh_title'.trParams({'name': widget.item.displayName}),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.bahtPerKg(line.unitPrice),
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          LiveScalePanel(
            pricePreview: (grams) => Formatters.baht(_lineFor(grams).lineTotal),
            // ต่อตาชั่งไว้ = ไม่ต้องพิมพ์ ปิดคีย์บอร์ดที่เด้งขึ้นมาบังตัวเลขบนแท็บเล็ต/มือถือ
            onAvailable: _kgFocus.unfocus,
            onUse: (grams) => Get.back(result: grams),
          ),
          TextField(
            controller: _kgController,
            focusNode: _kgFocus,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'order_weigh_kg_label'.tr,
              hintText: '0.485',
              suffixText: 'common_unit_kg'.tr,
              errorText: _kgController.text.isNotEmpty && grams == null
                  ? 'order_weigh_invalid'.tr
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Text(
            preview == null
                ? 'order_weigh_hint'.tr
                : 'order_weigh_preview'.trParams({
                    'weight': Formatters.weight(grams!),
                    'price': Formatters.baht(preview),
                  }),
            style: const TextStyle(fontWeight: FontWeight.w700),
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
          onPressed: grams == null ? null : _submit,
          child: Text('order_weigh_confirm'.tr),
        ),
      ],
    );
  }
}
