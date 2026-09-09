import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../../features/order/domain/entities/order_item_payload.dart';
import '../../features/order/domain/entities/pending_order_items.dart';
import '../../features/order/domain/repositories/order_repository.dart';
import '../errors/failures.dart';
import 'storage_service.dart';

/// คิวรายการอาหาร "สั่งเพิ่มเข้าออเดอร์เดิม" ที่ค้างส่งเพราะเน็ตหลุดตอนกดยืนยัน
///
/// ขอบเขตตั้งใจจำกัดแค่นี้ (ดู `docs/DECISIONS.md`) เพราะความเสี่ยง conflict ต่ำกว่าการเปิด
/// ออเดอร์ใหม่หรือชำระเงิน — เก็บคิวไว้ใน local storage แล้ว retry เป็นระยะจนกว่าจะสำเร็จ
/// หรือเจอความล้มเหลวที่ retry ไปก็ไม่มีทางสำเร็จ (เช่นออเดอร์ถูกปิด/ลบไปแล้วระหว่างออฟไลน์)
class OfflineOrderQueueService extends GetxService {
  OfflineOrderQueueService({
    required StorageService storage,
    required OrderRepository orderRepository,
    Duration retryInterval = const Duration(seconds: 20),
  }) : _storage = storage,
       _orderRepository = orderRepository,
       _retryInterval = retryInterval {
    pending.addAll(_load());
    if (pending.isNotEmpty) _scheduleSync();
  }

  final StorageService _storage;
  final OrderRepository _orderRepository;
  final Duration _retryInterval;
  Timer? _retryTimer;

  final RxList<PendingOrderItems> pending = <PendingOrderItems>[].obs;
  final RxBool isSyncing = false.obs;
  final RxnString lastFailureMessage = RxnString();

  int get pendingCount => pending.length;

  List<PendingOrderItems> _load() {
    final raw = _storage.pendingOrderItemsJson;
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(PendingOrderItems.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist() => _storage.savePendingOrderItems(
    jsonEncode(pending.map((entry) => entry.toJson()).toList()),
  );

  /// เก็บรายการที่ส่งไม่สำเร็จเพราะเน็ตหลุดไว้ในคิว แล้วเริ่มพยายามส่งใหม่ทันที + เป็นระยะ
  Future<void> enqueue({
    required int orderId,
    required String orderLabel,
    required List<OrderItemPayload> items,
    required String summary,
  }) async {
    pending.add(
      PendingOrderItems(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        orderId: orderId,
        orderLabel: orderLabel,
        items: items,
        summary: summary,
        queuedAt: DateTime.now(),
      ),
    );
    await _persist();
    _scheduleSync();
  }

  void _scheduleSync() {
    unawaited(syncNow());
    _retryTimer ??= Timer.periodic(_retryInterval, (_) => syncNow());
  }

  /// ลองส่งทุกรายการในคิวตามลำดับที่ queue ไว้ (กันโต๊ะเดียวกันสั่งสลับลำดับกับ backend)
  ///
  /// เจอ [NetworkFailure] (ยังออฟไลน์) → หยุดทั้งรอบ ไว้รอบหน้าลองใหม่ตามลำดับเดิม
  /// เจอความล้มเหลวอื่น (เช่นออเดอร์ถูกปิด/ลบไประหว่างออฟไลน์ — conflict จริง ไม่มีทาง
  /// สำเร็จถ้าลองซ้ำ) → ตัดออกจากคิว บันทึกข้อความไว้แจ้งผู้ใช้ แล้วไปต่อรายการถัดไป
  Future<void> syncNow() async {
    if (isSyncing.value || pending.isEmpty) return;
    isSyncing.value = true;

    for (final entry in pending.toList()) {
      final result = await _orderRepository.addItems(
        entry.orderId,
        entry.items,
      );
      final shouldStop = result.fold(
        onSuccess: (_) {
          pending.removeWhere((item) => item.id == entry.id);
          return false;
        },
        onFailure: (failure) {
          if (failure is NetworkFailure) return true;
          pending.removeWhere((item) => item.id == entry.id);
          lastFailureMessage.value =
              'ส่งรายการที่ค้างไว้ของ ${entry.orderLabel} ไม่สำเร็จ: '
              '${failure.message}';
          return false;
        },
      );
      await _persist();
      if (shouldStop) break;
    }

    isSyncing.value = false;
    if (pending.isEmpty) {
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }

  @override
  void onClose() {
    _retryTimer?.cancel();
    super.onClose();
  }
}
