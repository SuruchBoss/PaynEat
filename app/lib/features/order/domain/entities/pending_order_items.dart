import 'order_item_payload.dart';

/// รายการอาหารที่ "สั่งเพิ่ม" เข้าออเดอร์เดิมไว้ตอนเน็ตหลุด แล้วรอส่งขึ้นเซิร์ฟเวอร์อัตโนมัติ
/// เมื่อเน็ตกลับมา (ดู [OfflineOrderQueueService])
class PendingOrderItems {
  const PendingOrderItems({
    required this.id,
    required this.orderId,
    required this.orderLabel,
    required this.items,
    required this.summary,
    required this.queuedAt,
  });

  /// id ที่สร้างในเครื่อง ใช้แยกแต่ละรายการในคิว (ไม่เกี่ยวกับ id บนเซิร์ฟเวอร์)
  final String id;
  final int orderId;

  /// ข้อความแสดงอ้างอิงออเดอร์ให้พนักงานเห็น เช่น "โต๊ะ A3" หรือ "ออเดอร์ #12"
  final String orderLabel;
  final List<OrderItemPayload> items;

  /// สรุปรายการสั้น ๆ เช่น "ผัดกะเพรา x2, ส้มตำไทย x1" — เก็บไว้ตอน enqueue เพราะตอนนั้น
  /// ยังมีชื่อเมนูอยู่ครบ (ข้อมูลที่ persist มีแค่ menuItemId ไม่พอสร้างข้อความนี้ทีหลัง)
  final String summary;
  final DateTime queuedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'orderLabel': orderLabel,
    'items': items.map((item) => item.toJson()).toList(),
    'summary': summary,
    'queuedAt': queuedAt.toIso8601String(),
  };

  factory PendingOrderItems.fromJson(Map<String, dynamic> json) =>
      PendingOrderItems(
        id: json['id'] as String,
        orderId: json['orderId'] as int,
        orderLabel: json['orderLabel'] as String? ?? '',
        items: (json['items'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(OrderItemPayload.fromJson)
            .toList(),
        summary: json['summary'] as String? ?? '',
        queuedAt:
            DateTime.tryParse(json['queuedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
