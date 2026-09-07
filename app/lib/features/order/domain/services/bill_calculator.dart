import '../entities/cart_line.dart';

/// ผลการคำนวณบิล
class BillBreakdown {
  const BillBreakdown({
    required this.subtotal,
    required this.discount,
    required this.serviceCharge,
    required this.vat,
    required this.total,
  });

  final double subtotal;
  final double discount;
  final double serviceCharge;
  final double vat;
  final double total;

  static const BillBreakdown zero = BillBreakdown(
    subtotal: 0,
    discount: 0,
    serviceCharge: 0,
    vat: 0,
    total: 0,
  );
}

/// คำนวณยอดบิลฝั่งแอปเพื่อ "แสดงตัวอย่าง" ก่อนส่งขึ้นเซิร์ฟเวอร์
///
/// ใช้กฎเดียวกับฝั่ง backend (backend/src/modules/orders/order.calculator.js):
///   1) รวมราคาอาหาร
///   2) หักส่วนลด
///   3) บวก Service Charge จากยอดหลังหักส่วนลด
///   4) บวก VAT จาก (ยอดหลังหักส่วนลด + Service Charge)
///
/// ยอดจริงที่ใช้เก็บเงินยังยึดตามที่ backend คำนวณเสมอ
/// ตัวนี้มีไว้ให้พนักงานเห็นตัวเลขทันทีขณะกดสั่ง โดยไม่ต้องรอเน็ต
class BillCalculator {
  const BillCalculator({
    this.vatRate = 0.07,
    this.serviceChargeRate = 0.1,
    this.vatIncluded = false,
  });

  final double vatRate;
  final double serviceChargeRate;
  final bool vatIncluded;

  BillBreakdown fromCart(
    List<CartLine> lines, {
    double discountAmount = 0,
    double discountPercent = 0,
  }) {
    final subtotal = lines.fold<double>(0, (sum, line) => sum + line.lineTotal);
    return fromSubtotal(
      subtotal,
      discountAmount: discountAmount,
      discountPercent: discountPercent,
    );
  }

  BillBreakdown fromSubtotal(
    double subtotal, {
    double discountAmount = 0,
    double discountPercent = 0,
  }) {
    if (subtotal <= 0) return BillBreakdown.zero;

    final percentDiscount = discountPercent > 0
        ? _round(subtotal * (discountPercent.clamp(0, 100) / 100))
        : 0.0;
    final discount = _round(
      (percentDiscount + discountAmount).clamp(0, subtotal).toDouble(),
    );

    final afterDiscount = _round(subtotal - discount);
    final serviceCharge = _round(afterDiscount * serviceChargeRate);

    if (vatIncluded) {
      final gross = _round(afterDiscount + serviceCharge);
      return BillBreakdown(
        subtotal: subtotal,
        discount: discount,
        serviceCharge: serviceCharge,
        vat: _round(gross - gross / (1 + vatRate)),
        total: gross,
      );
    }

    final vat = _round((afterDiscount + serviceCharge) * vatRate);
    return BillBreakdown(
      subtotal: subtotal,
      discount: discount,
      serviceCharge: serviceCharge,
      vat: vat,
      total: _round(afterDiscount + serviceCharge + vat),
    );
  }

  /// ปัดเป็นทศนิยม 2 ตำแหน่งแบบเดียวกับที่ backend ปัดเป็นสตางค์
  static double _round(double value) => (value * 100).round() / 100;
}
