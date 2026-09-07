import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/socket_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../order/domain/entities/order_item.dart';
import '../../../order/domain/usecases/order_usecases.dart';

/// จอครัว (Kitchen Display System)
///
/// รับตั๋วอาหารแบบเรียลไทม์ผ่าน socket แล้วจัดกลุ่มเป็นคอลัมน์ตามสถานะ
/// มี timer เดินทุกนาทีเพื่ออัปเดต "รอมาแล้วกี่นาที" ให้ครัวเห็นว่าจานไหนช้า
class KitchenController extends GetxController {
  KitchenController({
    required GetKitchenQueueUseCase getQueue,
    required UpdateOrderItemStatusUseCase updateItemStatus,
    required SessionService session,
  }) : _getQueue = getQueue,
       _updateItemStatus = updateItemStatus,
       _session = session;

  final GetKitchenQueueUseCase _getQueue;
  final UpdateOrderItemStatusUseCase _updateItemStatus;
  final SessionService _session;

  final RxList<OrderItem> queue = <OrderItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxInt tick = 0.obs;

  /// นาทีที่ถือว่า "ช้า" แล้วต้องเน้นสีให้ครัวเห็น
  static const int lateThresholdMinutes = 15;

  final List<VoidCallback> _unsubscribers = [];
  Timer? _elapsedTimer;

  @override
  void onInit() {
    super.onInit();
    load();
    _listenToRealtimeUpdates();
    _elapsedTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => tick.value++,
    );
  }

  @override
  void onClose() {
    _elapsedTimer?.cancel();
    for (final unsubscribe in _unsubscribers) {
      unsubscribe();
    }
    super.onClose();
  }

  List<OrderItem> byStatus(String status) =>
      queue.where((item) => item.status == status).toList(growable: false);

  List<OrderItem> get pending => byStatus(OrderItemStatus.pending);
  List<OrderItem> get cooking => byStatus(OrderItemStatus.cooking);
  List<OrderItem> get ready => byStatus(OrderItemStatus.ready);

  int get lateCount => queue
      .where(
        (item) =>
            item.status != OrderItemStatus.ready &&
            _minutesWaiting(item) >= lateThresholdMinutes,
      )
      .length;

  int _minutesWaiting(OrderItem item) =>
      Formatters.elapsedMinutes(item.createdAt);

  bool isLate(OrderItem item) => _minutesWaiting(item) >= lateThresholdMinutes;

  Future<void> load({bool showLoader = true}) async {
    if (showLoader) isLoading.value = true;
    errorMessage.value = null;

    final result = await _getQueue(const [
      OrderItemStatus.pending,
      OrderItemStatus.cooking,
      OrderItemStatus.ready,
    ]);

    isLoading.value = false;
    result.fold(
      onSuccess: queue.assignAll,
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  /// ครัวกดปุ่มเดียวเพื่อเดินสถานะไปขั้นถัดไป
  Future<void> advance(OrderItem item) async {
    final next = item.nextStatus;
    if (next == null) return;

    // อัปเดตในเครื่องก่อนเพื่อให้ปุ่มตอบสนองทันที แล้วค่อย sync กับเซิร์ฟเวอร์
    final index = queue.indexWhere((row) => row.id == item.id);
    final result = await _updateItemStatus(
      UpdateItemStatusParams(
        orderId: item.orderId,
        itemId: item.id,
        status: next,
      ),
    );

    result.fold(
      onSuccess: (_) {
        if (next == OrderItemStatus.served && index >= 0) {
          queue.removeAt(index);
        } else {
          load(showLoader: false);
        }
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  void _listenToRealtimeUpdates() {
    final socket = _session.socket;
    for (final event in [
      SocketEvents.kitchenTicket,
      SocketEvents.orderItemUpdated,
      SocketEvents.orderUpdated,
    ]) {
      _unsubscribers.add(socket.on(event, (_) => load(showLoader: false)));
    }
  }
}
