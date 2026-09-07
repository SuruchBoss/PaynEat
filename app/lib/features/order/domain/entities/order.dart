import '../../../../core/constants/app_constants.dart';
import 'order_item.dart';

/// ออเดอร์ 1 ใบ (1 โต๊ะ หรือ 1 รายการกลับบ้าน)
class Order {
  const Order({
    required this.id,
    required this.code,
    required this.type,
    required this.status,
    required this.subtotal,
    required this.total,
    this.tableId,
    this.tableName,
    this.tableZone,
    this.waiterId,
    this.waiterName,
    this.guestCount = 1,
    this.note,
    this.discountType = DiscountType.none,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.serviceCharge = 0,
    this.vat = 0,
    this.cancelledReason,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.items = const [],
  });

  final int id;
  final String code;
  final String type;
  final String status;

  final int? tableId;
  final String? tableName;
  final String? tableZone;
  final int? waiterId;
  final String? waiterName;
  final int guestCount;
  final String? note;

  final double subtotal;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final double serviceCharge;
  final double vat;
  final double total;

  final String? cancelledReason;
  final String? createdAt;
  final String? updatedAt;
  final String? closedAt;
  final List<OrderItem> items;

  String get statusLabel => OrderStatus.label(status);
  String get typeLabel => OrderType.label(type);

  bool get isActive => OrderStatus.isActive(status);
  bool get isPaid => status == OrderStatus.paid;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get canSendToKitchen =>
      status == OrderStatus.open && activeItems.isNotEmpty;
  bool get hasDiscount =>
      discountType != DiscountType.none && discountAmount > 0;

  List<OrderItem> get activeItems =>
      items.where((item) => !item.isCancelled).toList(growable: false);

  int get totalQuantity =>
      activeItems.fold(0, (sum, item) => sum + item.quantity);

  /// ชื่อที่ใช้แสดงหัวออเดอร์ เช่น "โต๊ะ A3" หรือ "กลับบ้าน"
  String get displayTarget =>
      tableName != null ? 'โต๊ะ $tableName' : OrderType.label(type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Order && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
