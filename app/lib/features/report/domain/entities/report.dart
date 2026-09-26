// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/constants/app_constants.dart';

/// ยอดขายแยกตามช่องทางชำระเงิน
class PaymentMethodSales {
  const PaymentMethodSales({
    required this.method,
    required this.count,
    required this.amount,
  });

  final String method;
  final int count;
  final double amount;

  String get label => PaymentMethod.label(method);
}

/// ยอดขายแยกตามหมวดหมู่อาหาร
class CategorySales {
  const CategorySales({
    required this.category,
    required this.quantity,
    required this.revenue,
  });

  final String category;
  final int quantity;
  final double revenue;
}

/// เมนูขายดี
class TopItem {
  const TopItem({
    required this.name,
    required this.quantity,
    required this.revenue,
    this.menuItemId,
    this.weightKg,
  });

  final int? menuItemId;
  final String name;
  final int quantity;
  final double revenue;

  /// น้ำหนักรวมที่ขายได้ของสินค้าขายตามน้ำหนัก (กก.) — null = ขายเป็นชิ้น
  /// ([quantity] ของสินค้าแบบนี้คือจำนวนถุง ไม่ใช่ปริมาณที่ขายจริง)
  final double? weightKg;
}

/// ยอดขายรายชั่วโมง (ใช้วาดกราฟช่วงเวลาที่ลูกค้าเยอะ)
class HourlySales {
  const HourlySales({
    required this.hour,
    required this.orderCount,
    required this.total,
  });

  final int hour;
  final int orderCount;
  final double total;
}

/// ยอดขายรายวัน
class DailySales {
  const DailySales({
    required this.day,
    required this.orderCount,
    required this.total,
  });

  final String day;
  final int orderCount;
  final double total;
}

/// สรุปยอดขายตามช่วงเวลา
class SalesSummary {
  const SalesSummary({
    required this.from,
    required this.to,
    required this.orderCount,
    required this.guestCount,
    required this.subtotal,
    required this.discount,
    required this.serviceCharge,
    required this.vat,
    required this.netSales,
    required this.averagePerOrder,
    required this.averagePerGuest,
    this.promotionDiscount = 0,
    this.totalDiscount = 0,
    this.paymentMethods = const [],
    this.categories = const [],
  });

  final String from;
  final String to;
  final int orderCount;
  final int guestCount;
  final double subtotal;
  final double discount;
  // ส่วนลดจากโปรโมชันอัตโนมัติ แยกจาก discount (ที่พนักงานกรอกเอง) — รวมกันเป็น totalDiscount
  // (ดู docs/tickets/12-report-export.md)
  final double promotionDiscount;
  final double totalDiscount;
  final double serviceCharge;
  final double vat;
  final double netSales;
  final double averagePerOrder;
  final double averagePerGuest;
  final List<PaymentMethodSales> paymentMethods;
  final List<CategorySales> categories;

  static const SalesSummary empty = SalesSummary(
    from: '',
    to: '',
    orderCount: 0,
    guestCount: 0,
    subtotal: 0,
    discount: 0,
    serviceCharge: 0,
    vat: 0,
    netSales: 0,
    averagePerOrder: 0,
    averagePerGuest: 0,
  );
}

/// Z-report ปิดกะ/ปิดวัน — สรุปยอดขาย/ภาษี/ส่วนลด/ช่องทางชำระเงิน พร้อมกระทบยอดเงินสดถ้าผูกกับกะ
/// (ดู docs/tickets/12-report-export.md)
class ZReport {
  const ZReport({
    required this.isShiftReport,
    required this.orderCount,
    required this.guestCount,
    required this.subtotal,
    required this.discount,
    required this.promotionDiscount,
    required this.totalDiscount,
    required this.serviceCharge,
    required this.vat,
    required this.refundTotal,
    required this.netSales,
    this.paymentMethods = const [],
    this.receivableReceipts = const [],
    this.shiftId,
    this.date,
    this.openedByName,
    this.openedAt,
    this.closedByName,
    this.closedAt,
    this.openingCash,
    this.expectedCash,
    this.countedCash,
    this.variance,
  });

  final bool isShiftReport;
  final int orderCount;
  final int guestCount;
  final double subtotal;
  final double discount;
  final double promotionDiscount;
  final double totalDiscount;
  final double serviceCharge;
  final double vat;
  final double refundTotal;
  final double netSales;
  final List<PaymentMethodSales> paymentMethods;

  /// รับชำระหนี้ลูกค้าเครดิตระหว่างกะแยกตามช่องทาง — ไม่ใช่ยอดขายของกะนี้ แต่เงินสดส่วนนี้
  /// อยู่ในลิ้นชัก (ดู docs/DECISIONS.md #50)
  final List<PaymentMethodSales> receivableReceipts;

  // เฉพาะ Z-report ต่อกะ
  final int? shiftId;
  final String? date;
  final String? openedByName;
  final String? openedAt;
  final String? closedByName;
  final String? closedAt;
  final double? openingCash;
  final double? expectedCash;
  final double? countedCash;
  final double? variance;
}

/// ตัวนับสถานะสด ๆ ของร้าน
class LiveCounters {
  const LiveCounters({
    required this.openOrders,
    required this.occupiedTables,
    required this.totalTables,
    required this.pendingKitchenItems,
  });

  final int openOrders;
  final int occupiedTables;
  final int totalTables;
  final int pendingKitchenItems;

  double get occupancyRate =>
      totalTables == 0 ? 0 : occupiedTables / totalTables;

  static const LiveCounters empty = LiveCounters(
    openOrders: 0,
    occupiedTables: 0,
    totalTables: 0,
    pendingKitchenItems: 0,
  );
}

/// ข้อมูลทั้งหมดของหน้า Dashboard
class DashboardData {
  const DashboardData({
    required this.today,
    required this.live,
    this.hourly = const [],
    this.topItems = const [],
  });

  final SalesSummary today;
  final LiveCounters live;
  final List<HourlySales> hourly;
  final List<TopItem> topItems;

  static const DashboardData empty = DashboardData(
    today: SalesSummary.empty,
    live: LiveCounters.empty,
  );
}
