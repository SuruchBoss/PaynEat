import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/receivable.dart';
import 'receivable_document_dialog.dart';

/// ดูดอกเบี้ยผิดนัดที่จะคิด ณ วันนี้ก่อนกดออกใบแจ้ง (ดู docs/tickets/21-late-fees-credit-notes.md)
/// — คืนหมายเหตุที่กรอก (สตริงว่างได้) ถ้ากดยืนยัน, null = ยกเลิก
///
/// ไม่ได้ตั้งอัตรา/ไม่มีบิลที่ต้องคิด ก็ยังเปิดกล่องนี้ บอกเหตุผลตรง ๆ แทนปุ่มที่กดแล้วไม่เกิดอะไร
class LateFeeDialog extends StatefulWidget {
  const LateFeeDialog({super.key, required this.preview});

  final LateFeePreview preview;

  static Future<String?> show(LateFeePreview preview) =>
      Get.dialog<String>(LateFeeDialog(preview: preview));

  @override
  State<LateFeeDialog> createState() => _LateFeeDialogState();
}

class _LateFeeDialogState extends State<LateFeeDialog> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final secondary = TextStyle(fontSize: 12.5, color: AppColors.textSecondary);
    final canIssue = preview.isRateSet && preview.items.isNotEmpty;

    return AlertDialog(
      title: Text('receivable_late_fee_dialog_title'.tr),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!preview.isRateSet)
                Text(
                  'receivable_late_fee_rate_unset'.tr,
                  key: const ValueKey('late-fee-rate-unset'),
                )
              else ...[
                Text(
                  'receivable_late_fee_terms'.trParams({
                    'rate': percentText(preview.annualRate),
                    'grace': '${preview.graceDays}',
                    'date': preview.asOf,
                  }),
                  style: secondary,
                ),
                const SizedBox(height: 10),
                if (preview.items.isEmpty)
                  Text(
                    'receivable_late_fee_nothing'.tr,
                    key: const ValueKey('late-fee-nothing'),
                  )
                else ...[
                  for (final line in preview.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                                  'receivable_late_fee_line'.trParams({
                                    'from': line.periodFrom,
                                    'to': line.periodTo,
                                    'days': '${line.days}',
                                    'principal': Formatters.money(
                                      line.principal,
                                    ),
                                  }),
                                  style: secondary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(Formatters.money(line.amount)),
                        ],
                      ),
                    ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'receivable_late_fee_total'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        Formatters.baht(preview.total),
                        key: const ValueKey('late-fee-preview-total'),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _note,
                    maxLength: 300,
                    decoration: InputDecoration(
                      labelText: 'receivable_late_fee_note_label'.tr,
                    ),
                  ),
                  Text('receivable_late_fee_formula'.tr, style: secondary),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text(canIssue ? 'common_cancel'.tr : 'common_close'.tr),
        ),
        if (canIssue)
          FilledButton(
            key: const ValueKey('late-fee-confirm'),
            onPressed: () => Get.back(result: _note.text.trim()),
            child: Text('receivable_late_fee_issue'.tr),
          ),
      ],
    );
  }
}
