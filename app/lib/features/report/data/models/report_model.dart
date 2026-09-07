import '../../domain/entities/report.dart';

/// ตัวแปลง JSON ของรายงาน — ใช้ static method เพราะ entity เป็น immutable ล้วน
class ReportMapper {
  const ReportMapper._();

  static SalesSummary summaryFromJson(Map<String, dynamic> json) {
    final range = json['range'] as Map<String, dynamic>? ?? const {};
    return SalesSummary(
      from: range['from'] as String? ?? '',
      to: range['to'] as String? ?? '',
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      guestCount: (json['guestCount'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
      vat: (json['vat'] as num?)?.toDouble() ?? 0,
      netSales: (json['netSales'] as num?)?.toDouble() ?? 0,
      averagePerOrder: (json['averagePerOrder'] as num?)?.toDouble() ?? 0,
      averagePerGuest: (json['averagePerGuest'] as num?)?.toDouble() ?? 0,
      paymentMethods: (json['paymentMethods'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => PaymentMethodSales(
              method: item['method'] as String? ?? '',
              count: (item['count'] as num?)?.toInt() ?? 0,
              amount: (item['amount'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList(growable: false),
      categories: (json['categories'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => CategorySales(
              category: item['category'] as String? ?? '',
              quantity: (item['quantity'] as num?)?.toInt() ?? 0,
              revenue: (item['revenue'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList(growable: false),
    );
  }

  static TopItem topItemFromJson(Map<String, dynamic> json) => TopItem(
    menuItemId: (json['menuItemId'] as num?)?.toInt(),
    name: json['name'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
  );

  static DailySales dailyFromJson(Map<String, dynamic> json) => DailySales(
    day: json['day'] as String? ?? '',
    orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
  );

  static DashboardData dashboardFromJson(Map<String, dynamic> json) {
    final live = json['live'] as Map<String, dynamic>? ?? const {};
    return DashboardData(
      today: summaryFromJson(
        json['today'] as Map<String, dynamic>? ?? const {},
      ),
      live: LiveCounters(
        openOrders: (live['openOrders'] as num?)?.toInt() ?? 0,
        occupiedTables: (live['occupiedTables'] as num?)?.toInt() ?? 0,
        totalTables: (live['totalTables'] as num?)?.toInt() ?? 0,
        pendingKitchenItems:
            (live['pendingKitchenItems'] as num?)?.toInt() ?? 0,
      ),
      hourly: (json['hourly'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => HourlySales(
              hour: (item['hour'] as num?)?.toInt() ?? 0,
              orderCount: (item['orderCount'] as num?)?.toInt() ?? 0,
              total: (item['total'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList(growable: false),
      topItems: (json['topItems'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(topItemFromJson)
          .toList(growable: false),
    );
  }
}
