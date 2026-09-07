import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';

class SelectedOptionModel extends SelectedOption {
  const SelectedOptionModel({
    required super.id,
    required super.name,
    super.groupName,
    super.priceDelta,
  });

  factory SelectedOptionModel.fromJson(Map<String, dynamic> json) => SelectedOptionModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        groupName: json['groupName'] as String?,
        priceDelta: (json['priceDelta'] as num?)?.toDouble() ?? 0,
      );
}

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.orderId,
    required super.name,
    required super.unitPrice,
    required super.quantity,
    required super.lineTotal,
    required super.status,
    super.menuItemId,
    super.options,
    super.optionsPrice,
    super.note,
    super.createdAt,
    super.updatedAt,
    super.orderCode,
    super.tableName,
    super.orderType,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: (json['id'] as num).toInt(),
        orderId: (json['orderId'] as num?)?.toInt() ?? 0,
        menuItemId: (json['menuItemId'] as num?)?.toInt(),
        name: json['name'] as String? ?? '',
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        optionsPrice: (json['optionsPrice'] as num?)?.toDouble() ?? 0,
        lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
        orderCode: json['orderCode'] as String?,
        tableName: json['tableName'] as String?,
        orderType: json['orderType'] as String?,
        options: (json['options'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SelectedOptionModel.fromJson)
            .toList(growable: false),
      );
}

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.code,
    required super.type,
    required super.status,
    required super.subtotal,
    required super.total,
    super.tableId,
    super.tableName,
    super.tableZone,
    super.waiterId,
    super.waiterName,
    super.guestCount,
    super.note,
    super.discountType,
    super.discountValue,
    super.discountAmount,
    super.serviceCharge,
    super.vat,
    super.cancelledReason,
    super.createdAt,
    super.updatedAt,
    super.closedAt,
    super.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: (json['id'] as num).toInt(),
        code: json['code'] as String? ?? '',
        type: json['type'] as String? ?? 'dine_in',
        status: json['status'] as String? ?? 'open',
        tableId: (json['tableId'] as num?)?.toInt(),
        tableName: json['tableName'] as String?,
        tableZone: json['tableZone'] as String?,
        waiterId: (json['waiterId'] as num?)?.toInt(),
        waiterName: json['waiterName'] as String?,
        guestCount: (json['guestCount'] as num?)?.toInt() ?? 1,
        note: json['note'] as String?,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        discountType: json['discountType'] as String? ?? 'none',
        discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
        serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
        vat: (json['vat'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        cancelledReason: json['cancelledReason'] as String?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
        closedAt: json['closedAt'] as String?,
        items: (json['items'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(OrderItemModel.fromJson)
            .toList(growable: false),
      );
}
