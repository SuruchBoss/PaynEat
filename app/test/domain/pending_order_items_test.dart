import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/features/order/domain/entities/order_item_payload.dart';
import 'package:payneat_pos/features/order/domain/entities/pending_order_items.dart';

void main() {
  group('OrderItemPayload', () {
    test('toJson/fromJson ไป-กลับได้ค่าเดิมครบทุกฟิลด์', () {
      const payload = OrderItemPayload(
        menuItemId: 5,
        quantity: 2,
        optionIds: [1, 2],
        note: 'ไม่ใส่ผัก',
      );

      final restored = OrderItemPayload.fromJson(payload.toJson());

      expect(restored.menuItemId, 5);
      expect(restored.quantity, 2);
      expect(restored.optionIds, [1, 2]);
      expect(restored.note, 'ไม่ใส่ผัก');
    });

    test('fromJson ใช้ค่าเริ่มต้นเมื่อไม่มี optionIds/note', () {
      final restored = OrderItemPayload.fromJson(const {
        'menuItemId': 1,
        'quantity': 1,
      });

      expect(restored.optionIds, isEmpty);
      expect(restored.note, isNull);
    });
  });

  group('PendingOrderItems', () {
    test('toJson/fromJson ไป-กลับได้ค่าเดิมครบทุกฟิลด์', () {
      final entry = PendingOrderItems(
        id: 'q1',
        orderId: 7,
        orderLabel: 'โต๊ะ B2',
        items: const [OrderItemPayload(menuItemId: 1, quantity: 3)],
        summary: 'ผัดไทย x3',
        queuedAt: DateTime.utc(2026, 1, 1, 12, 0),
      );

      final restored = PendingOrderItems.fromJson(entry.toJson());

      expect(restored.id, 'q1');
      expect(restored.orderId, 7);
      expect(restored.orderLabel, 'โต๊ะ B2');
      expect(restored.summary, 'ผัดไทย x3');
      expect(restored.items.length, 1);
      expect(restored.items.first.menuItemId, 1);
      expect(restored.queuedAt, DateTime.utc(2026, 1, 1, 12, 0));
    });
  });
}
