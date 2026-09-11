import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../order/domain/entities/order_item.dart';

/// ตั๋วอาหาร 1 ใบบนจอครัว — เน้นตัวใหญ่ อ่านง่ายจากระยะไกลในครัว
class KitchenTicketCard extends StatelessWidget {
  const KitchenTicketCard({
    super.key,
    required this.item,
    required this.isLate,
    required this.onAdvance,
  });

  final OrderItem item;
  final bool isLate;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.itemStatus(item.status);
    final accent = isLate ? AppColors.danger : color;
    // จอครัวอ่านจากระยะไกลในที่ที่มีไอน้ำและแสงจ้า ตัวหนังสือบนหัวตั๋ว
    // (ชื่อโต๊ะ + เวลารอ) จึงต้องใช้เฉดเข้ม ไม่ใช้สีสดแบบเดียวกับเส้นขอบ
    final accentInk = isLate
        ? AppColors.dangerInk
        : AppColors.itemStatusInk(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.4),
          width: isLate ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: accent.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              children: [
                Icon(
                  item.tableName != null
                      ? Icons.table_restaurant_rounded
                      : Icons.takeout_dining_rounded,
                  size: 15,
                  color: accentInk,
                ),
                const SizedBox(width: 6),
                Text(
                  item.tableName != null
                      ? 'kitchen_table_label'.trParams({
                          'table': item.tableName!,
                        })
                      : OrderType.label(OrderType.takeaway),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: accentInk,
                  ),
                ),
                const Spacer(),
                Icon(
                  isLate
                      ? Icons.local_fire_department_rounded
                      : Icons.schedule_rounded,
                  size: 14,
                  color: accentInk,
                ),
                const SizedBox(width: 4),
                Text(
                  Formatters.elapsed(item.createdAt),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: accentInk,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'x${item.quantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.options.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: item.options
                          .map(
                            (option) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                option.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                if (item.note != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.campaign_rounded,
                          size: 15,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.note!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warningInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size(0, 56),
                    ),
                    onPressed: onAdvance,
                    child: Text(item.nextActionLabel ?? '-'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
