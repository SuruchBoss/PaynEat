import '../../../../core/constants/app_constants.dart';

/// ตัวเลือกที่ลูกค้าเลือกไว้ ณ ตอนสั่ง (snapshot — ราคาไม่เปลี่ยนตามเมนูภายหลัง)
class SelectedOption {
  const SelectedOption({
    required this.id,
    required this.name,
    this.groupName,
    this.priceDelta = 0,
  });

  final int id;
  final String name;
  final String? groupName;
  final double priceDelta;
}

/// รายการอาหาร 1 บรรทัดในออเดอร์
class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.status,
    this.menuItemId,
    this.options = const [],
    this.optionsPrice = 0,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.orderCode,
    this.tableName,
    this.orderType,
  });

  final int id;
  final int orderId;
  final int? menuItemId;
  final String name;
  final double unitPrice;
  final int quantity;
  final List<SelectedOption> options;
  final double optionsPrice;
  final double lineTotal;
  final String? note;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  // เติมมาเฉพาะตอนดึงจากคิวครัว
  final String? orderCode;
  final String? tableName;
  final String? orderType;

  String get statusLabel => OrderItemStatus.label(status);
  bool get isCancelled => status == OrderItemStatus.cancelled;
  bool get isEditable => status == OrderItemStatus.pending;
  String? get nextStatus => OrderItemStatus.next(status);
  String? get nextActionLabel => OrderItemStatus.nextActionLabel(status);

  String get optionsSummary => options.map((option) => option.name).join(' • ');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OrderItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
