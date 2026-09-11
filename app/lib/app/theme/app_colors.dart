import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// ระดับคอนทราสต์ของแอป
///
/// [high] ไม่ใช่ "ธีมที่สอง" แต่เป็นพาเลตต์เดิมที่เข้มขึ้น — โครงสีและความหมายของทุกสี
/// เหมือนเดิมเป๊ะ (ส้ม = แบรนด์, เหลือง = มีลูกค้า, แดง = อันตราย) เปลี่ยนแค่ความเข้ม
/// ของตัวหนังสือ/ขอบ/หมึก ให้ยังอ่านออกกลางแดดจ้าและบนจอครัวที่มีไอน้ำกับรอยนิ้วมือ
enum AppContrast { standard, high }

/// พาเลตต์สีของแอป — คุมโทน "ร้านอาหาร" ให้อบอุ่นแต่ยังอ่านง่ายบนจอสว่างจ้าในร้าน
class AppColors {
  const AppColors._();

  /// ระดับคอนทราสต์ที่ใช้อยู่ — ตั้งผ่าน [ContrastService] เท่านั้น
  ///
  /// เป็น static เพราะทั้งแอปเรียก `AppColors.x` ตรง ๆ 396 จุดใน 43 ไฟล์
  /// การส่งผ่าน BuildContext ทุกจุดจะเป็นการรื้อที่ไม่คุ้มกับสิ่งที่ได้
  static AppContrast contrast = AppContrast.standard;

  static bool get isHighContrast => contrast == AppContrast.high;

  static const Color primary = Color(0xFFFF6B2C);
  static const Color primaryDark = Color(0xFFE2551A);
  static const Color primarySoft = Color(0xFFFFF1EA);

  static const Color secondary = Color(0xFF12B886);
  static const Color secondarySoft = Color(0xFFE6F7F1);

  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static Color get surfaceAlt =>
      isHighContrast ? const Color(0xFFE2E6EA) : const Color(0xFFF0F2F5);

  static Color get textPrimary =>
      isHighContrast ? const Color(0xFF000000) : const Color(0xFF1A1D21);
  static Color get textSecondary =>
      isHighContrast ? const Color(0xFF2B3238) : const Color(0xFF6B7280);

  /// สงวนไว้ให้ "ปุ่ม/ช่องกรอกที่ถูกปิดใช้งาน" และ placeholder เท่านั้น
  /// โหมดปกติคอนทราสต์แค่ 2.54:1 จึงห้ามใช้กับข้อความที่ผู้ใช้ต้องอ่านจริง
  /// (ใช้ textSecondary แทน) — โหมดคอนทราสต์สูงดันขึ้นเป็น 6.70:1 เพื่อให้ placeholder
  /// ยังอ่านออกกลางแดด แต่ยังดูจางกว่าข้อความปกติอย่างชัดเจน
  static Color get textDisabled =>
      isHighContrast ? const Color(0xFF545D66) : const Color(0xFF9CA3AF);

  /// โหมดปกติขอบจางมาก (1.24:1) ตั้งใจให้การ์ดดูลอย ๆ ไม่รก
  /// โหมดคอนทราสต์สูงดันเป็น 4.10:1 ให้ผ่านเกณฑ์องค์ประกอบที่ไม่ใช่ตัวหนังสือ (3:1)
  /// เพราะกลางแดดจ้าขอบจาง ๆ หายไปเลย จนแยกไม่ออกว่าการ์ดไหนจบตรงไหน
  static Color get border =>
      isHighContrast ? const Color(0xFF767E89) : const Color(0xFFE5E7EB);

  static const Color success = Color(0xFF2F9E44);
  static const Color warning = Color(0xFFF59F00);
  static const Color danger = Color(0xFFE03131);
  static const Color info = Color(0xFF1971C2);
  static const Color purple = Color(0xFF7048E8);

  // ---------------------------------------------------------------- ink ----
  // สีชุดด้านบนถูกออกแบบมาเพื่อเป็น "พื้น/จุด/ขอบ" ซึ่งสว่างเกินกว่าจะเอามาเป็นตัวหนังสือ
  // บนพื้นขาวได้ (ส้มแบรนด์ได้แค่ 2.8:1 เหลืองอำพัน 2.1:1 — เกณฑ์ WCAG AA ต้อง 4.5:1)
  // ชุด *Ink ด้านล่างคือเฉดเข้มของสีเดียวกัน ใช้เฉพาะตอนเป็นตัวหนังสือ/ไอคอนบนพื้นสว่าง
  // ทุกค่าตรวจแล้วว่าผ่าน 4.5:1 ทั้งบนพื้นขาว พื้น background และพื้น soft ของสีตัวเอง
  //
  // สำคัญกับแอปนี้เป็นพิเศษ เพราะถูกใช้ในครัวที่มีไอน้ำ กลางแดดริมหน้าต่าง
  // และบนจอที่มีรอยนิ้วมือ — สภาพพวกนี้กินคอนทราสต์ไปอีกชั้นหนึ่ง
  // ตัวเลขท้ายบรรทัดคือคอนทราสต์บนพื้นขาว — โหมดปกติ / โหมดคอนทราสต์สูง
  // โหมดคอนทราสต์สูงดันทุกตัวให้ถึง AAA (7:1) ไม่ใช่แค่ AA (4.5:1)
  static Color get brandInk => isHighContrast
      ? const Color(0xFF9A3412) // 7.31:1
      : const Color(0xFFC2410C); // 5.18:1 — ราคา / ยอดเงิน

  static Color get warningInk => isHighContrast
      ? const Color(0xFF8A4008) // 7.45:1
      : const Color(0xFFB45309); // 5.02:1

  static Color get successInk => isHighContrast
      ? const Color(0xFF1A5A26) // 8.29:1
      : const Color(0xFF247532); // 5.73:1

  static Color get secondaryInk => isHighContrast
      ? const Color(0xFF075E46) // 7.78:1
      : const Color(0xFF0B7A5A); // 5.32:1 — เงินทอน

  static Color get dangerInk => isHighContrast
      ? const Color(0xFFA31D1D) // 7.63:1
      : const Color(0xFFC92A2A); // 5.46:1

  static Color get purpleInk => isHighContrast
      ? const Color(0xFF4526A8) // 10.02:1
      : const Color(0xFF5B34D1); // 7.35:1

  static Color get infoInk => isHighContrast
      ? const Color(0xFF12548F) // 7.81:1
      : info; // 5.02:1 อยู่แล้ว ไม่ต้องเข้มเพิ่ม

  /// แปลงสีพื้นให้เป็นเฉด "หมึก" ที่อ่านออกบนพื้นสว่าง
  ///
  /// มีไว้ให้ widget กลางอย่าง [StatusChip] ที่รับสีมาจากผู้เรียกแล้วเอาไปวาดเป็นตัวหนังสือ
  /// บนพื้นสีอ่อนของสีเดียวกัน — เรียกครั้งเดียวในนั้น ทุกจุดที่ใช้ chip จึงถูกต้องตามไปหมด
  /// สีที่ไม่รู้จัก (เช่นสีที่ผ่านมาจาก data) จะคืนค่าเดิมไป ไม่เดาให้
  static Color inkOf(Color color) => switch (color) {
    primary => brandInk,
    warning => warningInk,
    success => successInk,
    secondary => secondaryInk,
    danger => dangerInk,
    purple => purpleInk,
    _ => color,
  };

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

  /// คู่แฝดเฉดเข้มของ [tableStatus] สำหรับตัวหนังสือบนการ์ดโต๊ะ (ยอดค้าง/ชื่อสถานะ)
  /// พื้นการ์ด จุดสถานะ และเส้นขอบยังใช้ [tableStatus] ตัวสว่างเหมือนเดิม
  static Color tableStatusInk(String status) => switch (status) {
    TableStatus.available => successInk,
    TableStatus.occupied => warningInk,
    TableStatus.reserved => infoInk,
    TableStatus.billing => purpleInk,
    _ => textSecondary,
  };

  /// คู่แฝดเฉดเข้มของ [itemStatus] สำหรับตัวหนังสือบนตั๋วครัว
  static Color itemStatusInk(String status) => switch (status) {
    OrderItemStatus.pending => warningInk,
    OrderItemStatus.cooking => brandInk,
    OrderItemStatus.ready => successInk,
    OrderItemStatus.served => infoInk,
    OrderItemStatus.cancelled => dangerInk,
    _ => textSecondary,
  };

  /// สีประจำช่องทางชำระเงิน
  ///
  /// ผูกกับตัวช่องทางเอง ไม่ใช่ลำดับที่ปรากฏในรายการ — ถ้าไล่สีตามลำดับ
  /// สีเดียวกันจะหมายถึงคนละช่องทางในแต่ละวัน ขึ้นกับว่าวันนั้นมีช่องทางไหนขายได้บ้าง
  static Color paymentMethod(String method) => switch (method) {
    PaymentMethod.cash => success,
    PaymentMethod.qr => info,
    PaymentMethod.card => warning,
    PaymentMethod.transfer => purple,
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
