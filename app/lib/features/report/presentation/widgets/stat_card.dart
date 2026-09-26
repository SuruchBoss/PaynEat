// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';

/// การ์ดตัวเลขสรุป 1 ค่า
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                // ไอคอนวางบนพื้น tint ของสีตัวเอง สีสดจึงจมหายไป
                // (ส้ม 2.50:1 เหลือง 1.94:1) ต้องใช้เฉดเข้มเสมอ
                child: Icon(icon, size: 18, color: AppColors.inkOf(color)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// วางการ์ดสรุปเป็นแถว ๆ ละ [columns] ใบ สูงเท่าเนื้อหาของใบที่สูงสุดในแถว
///
/// เดิมใช้ GridView.count + childAspectRatio ความสูงการ์ดจึงผูกกับความกว้าง พอจอแคบลง
/// (มือถือ 360px) หรือผู้ใช้ขยายตัวอักษรของระบบ การ์ดเตี้ยกว่าเนื้อหาแล้วล้น 4–6px ทุกใบ
/// ในหน้าภาพรวมและรายงาน (เจอตอนไล่ถ่ายทุกหน้าก่อน UAT — docs/DECISIONS.md #62)
class StatGrid extends StatelessWidget {
  const StatGrid({
    super.key,
    required this.columns,
    required this.children,
    this.spacing = 12,
  });

  final int columns;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final cells = <Widget>[];
      for (var i = 0; i < columns; i++) {
        if (i > 0) cells.add(SizedBox(width: spacing));
        final index = start + i;
        cells.add(
          Expanded(
            child: index < children.length
                ? children[index]
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
