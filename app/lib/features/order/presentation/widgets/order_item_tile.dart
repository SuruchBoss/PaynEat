import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/order_item.dart';

/// แถวรายการอาหารในออเดอร์ พร้อมปุ่มเดินสถานะและปุ่มลบ
class OrderItemTile extends StatelessWidget {
  const OrderItemTile({
    super.key,
    required this.item,
    this.onAdvance,
    this.onCancel,
    this.onRemove,
    this.showActions = true,
  });

  final OrderItem item;
  final VoidCallback? onAdvance;
  final VoidCallback? onCancel;
  final VoidCallback? onRemove;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.itemStatus(item.status);

    return Opacity(
      opacity: item.isCancelled ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${item.quantity}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            decoration: item.isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.baht(item.lineTotal),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (item.options.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.optionsSummary,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  if (item.note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_note_rounded,
                            size: 13,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.note!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warningInk,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusChip(
                        label: OrderItemStatus.label(item.status),
                        color: color,
                        dense: true,
                      ),
                      const Spacer(),
                      if (showActions && !item.isCancelled) ...[
                        if (onRemove != null && item.isEditable)
                          IconButton(
                            onPressed: onRemove,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            visualDensity: VisualDensity.compact,
                            color: AppColors.textSecondary,
                            tooltip: 'order_remove_item'.tr,
                          ),
                        if (onCancel != null && !item.isEditable)
                          IconButton(
                            onPressed: onCancel,
                            icon: const Icon(Icons.block_rounded, size: 17),
                            visualDensity: VisualDensity.compact,
                            color: AppColors.textSecondary,
                            tooltip: 'order_cancel_item'.tr,
                          ),
                        if (onAdvance != null && item.nextActionLabel != null)
                          FilledButton(
                            onPressed: onAdvance,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              backgroundColor: color,
                              // ต้อง copyWith จาก labelLarge ของธีม ไม่ใช่สร้าง TextStyle
                              // เปล่า ๆ ขึ้นใหม่ — ไม่งั้น fontFamily จะหลุดไปใช้ค่า default
                              // ของแพลตฟอร์ม (ดูคำเตือนเดียวกันใน app_theme.dart)
                              textStyle: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            child: Text(item.nextActionLabel!),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
