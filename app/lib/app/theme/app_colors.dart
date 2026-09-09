import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// พาเลตต์สีของแอป — คุมโทน "ร้านอาหาร" ให้อบอุ่นแต่ยังอ่านง่ายบนจอสว่างจ้าในร้าน
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFFFF6B2C);
  static const Color primaryDark = Color(0xFFE2551A);
  static const Color primarySoft = Color(0xFFFFF1EA);

  static const Color secondary = Color(0xFF12B886);
  static const Color secondarySoft = Color(0xFFE6F7F1);

  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0F2F5);

  static const Color textPrimary = Color(0xFF1A1D21);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);

  static const Color success = Color(0xFF2F9E44);
  static const Color warning = Color(0xFFF59F00);
  static const Color danger = Color(0xFFE03131);
  static const Color info = Color(0xFF1971C2);
  static const Color purple = Color(0xFF7048E8);

  /// สีประจำสถานะโต๊ะ ใช้ทั้งในผังโต๊ะและ chip
  ///
  /// ตั้งใจไม่ใช้ [primary] กับสถานะไหนเลย — ส้มแบรนด์ถูกใช้เป็นสี CTA/แท็บที่เลือกอยู่
  /// ทั่วแอปอยู่แล้ว ถ้าเอามาใช้ซ้ำเป็นสีสถานะโต๊ะด้วย จะแยกไม่ออกว่าส้มหมายถึงอะไรกันแน่
  static Color tableStatus(String status) => switch (status) {
    TableStatus.available => success,
    TableStatus.occupied => warning,
    TableStatus.reserved => info,
    TableStatus.billing => purple,
    _ => textSecondary,
  };

  /// สีประจำสถานะรายการอาหารบนจอครัว
  static Color itemStatus(String status) => switch (status) {
    OrderItemStatus.pending => warning,
    OrderItemStatus.cooking => primary,
    OrderItemStatus.ready => success,
    OrderItemStatus.served => info,
    OrderItemStatus.cancelled => danger,
    _ => textSecondary,
  };

  static Color orderStatus(String status) => switch (status) {
    OrderStatus.open => info,
    OrderStatus.inKitchen => primary,
    OrderStatus.served => success,
    OrderStatus.paid => textSecondary,
    OrderStatus.cancelled => danger,
    _ => textSecondary,
  };
}
