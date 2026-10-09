// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/merge_preview.dart';

/// ยืนยันการรวมบิลพร้อมยอดของทั้งสองฝั่ง (T09 #96, docs/DECISIONS.md #77 D3, #98) — ยอดจ่ายแล้วและส่วนลดของบิลต้นทาง
/// ย้ายตามไปที่บิลนี้ ถ้าส่วนลดรวมจะลดลงหรือยอดหลังรวมต่ำกว่าเงินที่รับไว้ต้องเห็นบนจอนี้ก่อนกดยืนยัน
class MergePreviewDialog extends StatelessWidget {
  const MergePreviewDialog({
    super.key,
    required this.preview,
    required this.sourceLabel,
    required this.targetLabel,
  });

  final MergePreview preview;
  final String sourceLabel;
  final String targetLabel;

  static Future<bool> show(
    MergePreview preview, {
    required String sourceLabel,
    required String targetLabel,
  }) async =>
      await Get.dialog<bool>(
        MergePreviewDialog(
          preview: preview,
          sourceLabel: sourceLabel,
          targetLabel: targetLabel,
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('order_merge_confirm_title'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'order_merge_preview_intro'.trParams({
                  'source': sourceLabel,
                  'target': targetLabel,
                }),
              ),
              const SizedBox(height: 12),
              _side(theme, 'order_merge_preview_source'.tr, preview.source),
              const SizedBox(height: 8),
              _side(theme, 'order_merge_preview_target'.tr, preview.target),
              const Divider(height: 24),
              Text(
                'order_merge_preview_after'.tr,
                style: theme.textTheme.titleSmall,
              ),
              _row('order_merge_preview_total'.tr, preview.total),
              if (preview.discount > 0)
                _row('order_merge_preview_discount'.tr, preview.discount),
              if (preview.promotionDiscount > 0)
                _row(
                  preview.promotionName ?? 'order_merge_preview_promotion'.tr,
                  preview.promotionDiscount,
                ),
              _row('order_merge_preview_paid'.tr, preview.paid),
              _row('order_merge_preview_remaining'.tr, preview.remaining),
              if (preview.discountLost > 0)
                _notice(
                  theme,
                  'order_merge_preview_discount_lost'.trParams({
                    'amount': Formatters.baht(preview.discountLost),
                  }),
                ),
              if (!preview.canMerge)
                _notice(
                  theme,
                  'order_merge_preview_refund_required'.trParams({
                    'amount': Formatters.baht(preview.refundRequired),
                  }),
                ),
              const SizedBox(height: 12),
              Text(
                'order_merge_preview_irreversible'.tr,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text(
            'common_cancel'.tr,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: preview.canMerge ? () => Get.back(result: true) : null,
          child: Text('order_merge_confirm_button'.tr),
        ),
      ],
    );
  }

  Widget _side(ThemeData theme, String label, MergePreviewSide side) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label #${side.code}', style: theme.textTheme.titleSmall),
      _row('order_merge_preview_total'.tr, side.total),
      _row('order_merge_preview_paid'.tr, side.paid),
      if (side.discount > 0)
        _row('order_merge_preview_discount'.tr, side.discount),
      if (side.promotionDiscount > 0)
        _row(
          side.promotionName ?? 'order_merge_preview_promotion'.tr,
          side.promotionDiscount,
        ),
    ],
  );

  Widget _row(String label, double amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(Formatters.baht(amount)),
      ],
    ),
  );

  Widget _notice(ThemeData theme, String message) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ],
    ),
  );
}
