import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/services/offline_order_queue_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/entities/order_item_payload.dart';
import 'package:payneat_pos/features/order/domain/entities/pending_order_items.dart';
import 'package:payneat_pos/features/order/domain/repositories/order_repository.dart';

Order _order({int id = 1}) => Order(
  id: id,
  code: 'A00$id',
  type: 'dine_in',
  status: 'open',
  subtotal: 100,
  total: 100,
);

const _items = [
  OrderItemPayload(menuItemId: 1, quantity: 2),
  OrderItemPayload(menuItemId: 2, quantity: 1),
];

/// repository ปลอม — คืนผลลัพธ์ตามคิวที่กำหนดไว้ล่วงหน้าต่อ orderId (เรียกครั้งที่เท่าไหร่
/// ก็ pop ออกจากคิวของ orderId นั้นตามลำดับ)
class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository(this._queuedResults);

  final Map<int, List<Result<Order>>> _queuedResults;
  final List<int> addItemsCalls = [];

  @override
  Future<Result<Order>> addItems(
    int orderId,
    List<OrderItemPayload> items,
  ) async {
    addItemsCalls.add(orderId);
    final queue = _queuedResults[orderId];
    if (queue == null || queue.isEmpty) {
      return Result.success(_order(id: orderId));
    }
    return queue.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('OfflineOrderQueueService', () {
    test('enqueue เพิ่มรายการลงคิวทันทีและ persist ลง storage', () async {
      final storage = StorageService.memory();
      final service = OfflineOrderQueueService(
        storage: storage,
        orderRepository: _FakeOrderRepository({
          1: [const Result.failure(NetworkFailure())],
        }),
        retryInterval: const Duration(minutes: 10),
      );

      await service.enqueue(
        orderId: 1,
        orderLabel: 'โต๊ะ A1',
        items: _items,
        summary: 'ข้าวผัดกุ้ง x2, ต้มยำกุ้ง x1',
      );

      expect(service.pending.length, 1);
      expect(service.pending.first.orderId, 1);
      expect(service.pending.first.summary, 'ข้าวผัดกุ้ง x2, ต้มยำกุ้ง x1');

      service.onClose();
    });

    test(
      'enqueue แล้ว sync อัตโนมัติสำเร็จ → ลบรายการออกจากคิวและ storage',
      () async {
        final storage = StorageService.memory();
        final service = OfflineOrderQueueService(
          storage: storage,
          orderRepository: _FakeOrderRepository({
            1: [Result.success(_order())],
          }),
          retryInterval: const Duration(minutes: 10),
        );

        await service.enqueue(
          orderId: 1,
          orderLabel: 'โต๊ะ A1',
          items: _items,
          summary: 'ข้าวผัดกุ้ง x2',
        );
        // รอ background sync ที่ enqueue() จุดชนวนไว้ให้ทำงานจบ (fire-and-forget)
        await Future<void>.delayed(Duration.zero);

        expect(service.pending, isEmpty);
        expect(storage.pendingOrderItemsJson, '[]');

        service.onClose();
      },
    );

    test(
      'syncNow เจอ NetworkFailure ของรายการแรก → หยุดทั้งรอบ ไม่แตะรายการถัดไป',
      () async {
        final repo = _FakeOrderRepository({
          1: [const Result.failure(NetworkFailure())],
        });
        final storage = StorageService.memory();
        final service = OfflineOrderQueueService(
          storage: storage,
          orderRepository: repo,
          retryInterval: const Duration(minutes: 10),
        );
        service.pending.addAll([
          PendingOrderItems(
            id: '1',
            orderId: 1,
            orderLabel: 'โต๊ะ A1',
            items: _items,
            summary: 'ข้าวผัดกุ้ง x2',
            queuedAt: DateTime.now(),
          ),
          PendingOrderItems(
            id: '2',
            orderId: 2,
            orderLabel: 'โต๊ะ A2',
            items: _items,
            summary: 'ส้มตำไทย x1',
            queuedAt: DateTime.now(),
          ),
        ]);

        await service.syncNow();

        expect(service.pending.length, 2);
        expect(repo.addItemsCalls, [
          1,
        ]); // ไม่เรียกรายการที่ 2 เพราะหยุดตั้งแต่รายการแรก
        expect(service.isSyncing.value, isFalse);

        service.onClose();
      },
    );

    test(
      'syncNow เจอความล้มเหลวอื่น (conflict) → ตัดรายการนั้นทิ้งและไปต่อรายการถัดไป',
      () async {
        final repo = _FakeOrderRepository({
          1: [
            const Result.failure(ValidationFailure('ออเดอร์นี้ถูกปิดไปแล้ว')),
          ],
          2: [Result.success(_order(id: 2))],
        });
        final storage = StorageService.memory();
        final service = OfflineOrderQueueService(
          storage: storage,
          orderRepository: repo,
          retryInterval: const Duration(minutes: 10),
        );
        service.pending.addAll([
          PendingOrderItems(
            id: '1',
            orderId: 1,
            orderLabel: 'โต๊ะ A1',
            items: _items,
            summary: 'ข้าวผัดกุ้ง x2',
            queuedAt: DateTime.now(),
          ),
          PendingOrderItems(
            id: '2',
            orderId: 2,
            orderLabel: 'โต๊ะ A2',
            items: _items,
            summary: 'ส้มตำไทย x1',
            queuedAt: DateTime.now(),
          ),
        ]);

        await service.syncNow();

        expect(service.pending, isEmpty);
        expect(repo.addItemsCalls, [1, 2]);
        expect(service.lastFailureMessage.value, contains('โต๊ะ A1'));
        expect(
          service.lastFailureMessage.value,
          contains('ออเดอร์นี้ถูกปิดไปแล้ว'),
        );

        service.onClose();
      },
    );

    test(
      'โหลดคิวที่ persist ไว้กลับมาได้ตอนสร้าง service ใหม่ (เช่นเปิดแอปใหม่)',
      () async {
        final storage = StorageService.memory();
        final first = OfflineOrderQueueService(
          storage: storage,
          orderRepository: _FakeOrderRepository({
            1: [const Result.failure(NetworkFailure())],
          }),
          retryInterval: const Duration(minutes: 10),
        );
        await first.enqueue(
          orderId: 1,
          orderLabel: 'โต๊ะ A1',
          items: _items,
          summary: 'ข้าวผัดกุ้ง x2, ต้มยำกุ้ง x1',
        );
        first.onClose();

        final second = OfflineOrderQueueService(
          storage: storage,
          orderRepository: _FakeOrderRepository({
            1: [const Result.failure(NetworkFailure())],
          }),
          retryInterval: const Duration(minutes: 10),
        );

        expect(second.pending.length, 1);
        expect(second.pending.first.orderId, 1);
        expect(second.pending.first.orderLabel, 'โต๊ะ A1');
        expect(second.pending.first.summary, 'ข้าวผัดกุ้ง x2, ต้มยำกุ้ง x1');
        expect(second.pending.first.items.length, 2);
        expect(second.pending.first.items.first.menuItemId, 1);

        second.onClose();
      },
    );
  });
}
