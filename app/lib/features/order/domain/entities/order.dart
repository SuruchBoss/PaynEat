// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

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
    this.queueNumber,
    this.waiterId,
    this.waiterName,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.pointsEarned = 0,
    this.guestCount = 1,
    this.note,
    this.discountType = DiscountType.none,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.promotionId,
    this.promotionName,
    this.promotionCode,
    this.promotionDiscountAmount = 0,
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
  // เลขคิวรับอาหาร รันต่อวัน — มีเฉพาะออเดอร์ type=takeaway เท่านั้น (ดู
  // docs/tickets/10-takeaway-delivery-flow.md)
  final int? queueNumber;
  final int? waiterId;
  final String? waiterName;
  // ผูกลูกค้าแบบ optional (ดู docs/tickets/09-customer-loyalty.md)
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final int pointsEarned;
  final int guestCount;
  final String? note;

  final double subtotal;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final int? promotionId;
  final String? promotionName;
  final String? promotionCode;
  final double promotionDiscountAmount;
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
  bool get hasPromotion => promotionId != null && promotionDiscountAmount > 0;

  List<OrderItem> get activeItems =>
      items.where((item) => !item.isCancelled).toList(growable: false);

  int get totalQuantity =>
      activeItems.fold(0, (sum, item) => sum + item.quantity);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Order && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
