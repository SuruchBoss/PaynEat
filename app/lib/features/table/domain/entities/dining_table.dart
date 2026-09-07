import '../../../../core/constants/app_constants.dart';

/// สรุปออเดอร์ที่กำลังเปิดอยู่บนโต๊ะ (ใช้แสดงบนการ์ดผังโต๊ะ)
class TableOrderSummary {
  const TableOrderSummary({
    required this.id,
    required this.code,
    required this.status,
    required this.total,
    this.guestCount = 0,
    this.createdAt,
  });

  final int id;
  final String code;
  final String status;
  final double total;
  final int guestCount;
  final String? createdAt;
}

/// โต๊ะในร้าน
class DiningTable {
  const DiningTable({
    required this.id,
    required this.name,
    required this.zone,
    required this.seats,
    required this.status,
    this.isActive = true,
    this.currentOrder,
  });

  final int id;
  final String name;
  final String zone;
  final int seats;
  final String status;
  final bool isActive;
  final TableOrderSummary? currentOrder;

  bool get isAvailable => status == TableStatus.available;
  bool get hasOpenOrder => currentOrder != null;
  String get statusLabel => TableStatus.label(status);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DiningTable && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
