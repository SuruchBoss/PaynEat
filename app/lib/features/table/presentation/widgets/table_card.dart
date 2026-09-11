import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/dining_table.dart';

/// การ์ดโต๊ะในผังร้าน — ออกแบบให้ดูปราดเดียวรู้ว่าโต๊ะไหนว่าง/มีลูกค้า/รอเก็บเงิน
class TableCard extends StatelessWidget {
  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
    this.onLongPress,
  });

  final DiningTable table;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    // แยกสองบทบาท: color ใช้ทำพื้น/ขอบ/จุดสถานะ ส่วน ink ใช้กับตัวหนังสือ
    // (ยอดค้างกับชื่อสถานะ เป็นสองอย่างที่พนักงานต้องอ่านจากระยะห่างและกลางแดด)
    final color = AppColors.tableStatus(table.status);
    final ink = AppColors.tableStatusInk(table.status);
    final order = table.currentOrder;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 1.4,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: 0.07), Colors.white],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      table.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 13,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'table_seat_count'.trParams({
                      'count': table.seats.toString(),
                    }),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (order != null) ...[
                Text(
                  Formatters.baht(order.total),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.code.split('-').last} · ${Formatters.elapsed(order.createdAt)}',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ] else
                Text(
                  TableStatus.label(table.status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
