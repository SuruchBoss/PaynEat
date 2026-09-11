import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../promotion/domain/entities/promotion.dart';

/// ผลลัพธ์จากกล่องโปรโมชัน — กรอกโค้ดใหม่ หรือเอาโปรโมชันที่ผูกไว้ออก
class PromotionDialogResult {
  const PromotionDialogResult.redeem(this.code) : isRemove = false;

  const PromotionDialogResult.remove() : code = null, isRemove = true;

  final String? code;
  final bool isRemove;
}

/// กล่องแสดงโปรโมชันที่ใช้ได้ตอนนี้ พร้อมช่องกรอกโค้ดส่วนลด
class PromotionCodeDialog extends StatefulWidget {
  const PromotionCodeDialog({
    super.key,
    required this.eligible,
    this.currentPromotionCode,
  });

  final List<EligiblePromotion> eligible;
  final String? currentPromotionCode;

  static Future<PromotionDialogResult?> show({
    required List<EligiblePromotion> eligible,
    String? currentPromotionCode,
  }) {
    return Get.dialog<PromotionDialogResult>(
      PromotionCodeDialog(
        eligible: eligible,
        currentPromotionCode: currentPromotionCode,
      ),
    );
  }

  @override
  State<PromotionCodeDialog> createState() => _PromotionCodeDialogState();
}

class _PromotionCodeDialogState extends State<PromotionCodeDialog> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('promotion_dialog_title'.tr),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.eligible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'promotion_dialog_none_available'.tr,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              )
            else
              ...widget.eligible.map(
                (promotion) => _PromotionRow(promotion: promotion),
              ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'promotion_dialog_code_section'.tr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'promotion_dialog_code_hint'.tr,
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.currentPromotionCode != null)
          TextButton(
            onPressed: () =>
                Get.back(result: const PromotionDialogResult.remove()),
            child: Text(
              'promotion_dialog_remove_button'.tr,
              style: TextStyle(color: AppColors.dangerInk),
            ),
          ),
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text('common_close'.tr),
        ),
        FilledButton(
          onPressed: _codeController.text.trim().isEmpty
              ? null
              : () => Get.back(
                  result: PromotionDialogResult.redeem(
                    _codeController.text.trim(),
                  ),
                ),
          child: Text('promotion_dialog_apply_code_button'.tr),
        ),
      ],
    );
  }
}

class _PromotionRow extends StatelessWidget {
  const _PromotionRow({required this.promotion});

  final EligiblePromotion promotion;

  @override
  Widget build(BuildContext context) {
    final badgeText = promotion.isCurrentlyApplied
        ? 'promotion_dialog_badge_applied'.tr
        : promotion.requiresCode
        ? 'promotion_dialog_badge_needs_code'.tr
        : 'promotion_dialog_badge_auto'.tr;
    final badgeColor = promotion.isCurrentlyApplied
        ? AppColors.success
        : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 11, color: badgeColor),
                  ),
                ),
              ],
            ),
          ),
          if (promotion.discountAmountIfApplied > 0)
            Text(
              '-${Formatters.money(promotion.discountAmountIfApplied)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.successInk,
              ),
            ),
        ],
      ),
    );
  }
}
