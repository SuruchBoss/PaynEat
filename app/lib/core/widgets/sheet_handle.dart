import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// ขีดจับลากหัว bottom sheet — บอกผู้ใช้ว่าปัดลงเพื่อปิดได้ โดยไม่ต้องมีปุ่มปิดกินพื้นที่บนจอมือถือ
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key, this.bottomSpacing = 14});

  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: EdgeInsets.only(bottom: bottomSpacing),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
