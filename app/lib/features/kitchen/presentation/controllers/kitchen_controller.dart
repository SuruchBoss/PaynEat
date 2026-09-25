import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
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

  /// จอครัวขาดการเชื่อมต่อเรียลไทม์อยู่หรือไม่ — ใช้ขึ้นแถบเตือนบนหน้าจอ
  final RxBool isOffline = false.obs;

  /// นาทีที่ถือว่า "ช้า" แล้วต้องเน้นสีให้ครัวเห็น
  static const int lateThresholdMinutes = 15;

  /// การเดินสถานะล่าสุดที่ยังย้อนได้ — จอครัวโชว์แถบ "เลิกทำ" จากค่านี้ (DECISIONS #64)
  /// เดิมกดผิด (เช่น "ทำเสร็จแล้ว" ทั้งที่ยังไม่เสร็จ) ต้องเดินหน้าต่อหรือตามผู้จัดการมายกเลิก
  final Rxn<KitchenStatusChange> lastChange = Rxn<KitchenStatusChange>();

  /// แถบเลิกทำค้างให้กดได้นานเท่านี้ พอให้คนเห็นว่ากดผิด แต่ไม่ค้างจนบังตั๋วถัดไป
  static const undoWindow = Duration(seconds: 8);

  final List<VoidCallback> _unsubscribers = [];
  Timer? _elapsedTimer;
  Timer? _undoTimer;

  @override
  void onInit() {
    super.onInit();
    load();
    _listenToRealtimeUpdates();

    _syncConnectionState();
    _session.socket.connected.addListener(_syncConnectionState);

    // ตัวจับเวลานี้ทำสองหน้าที่:
    // 1. เดินตัวเลข "รอมาแล้วกี่นาที" บนตั๋ว
    // 2. เป็น polling สำรองตอน socket หลุด — จอครัวเป็นจอเดียวที่ไม่มีคนคอยกดรีเฟรช
    //    ถ้าพึ่ง socket อย่างเดียว เน็ตสะดุดทีเดียวตั๋วจะหยุดเข้าเงียบ ๆ ทั้งที่ตัวเลขนาที
    //    ยังเดินอยู่ ทำให้ดูเหมือนทุกอย่างปกติ
    _elapsedTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      tick.value++;
      if (isOffline.value) load(showLoader: false);
    });
  }

  @override
  void onClose() {
    _elapsedTimer?.cancel();
    _undoTimer?.cancel();
    _session.socket.connected.removeListener(_syncConnectionState);
    for (final unsubscribe in _unsubscribers) {
      unsubscribe();
    }
    super.onClose();
  }

  /// โหมดสาธิตตั้งใจทำงานโดยไม่มีเซิร์ฟเวอร์ การไม่มี socket จึงเป็นเรื่องปกติ
  /// ไม่ใช่ความผิดปกติที่ต้องเตือน — ถ้าไม่กันไว้ แถบแดงจะขึ้นค้างตลอดทั้งที่ทุกอย่างใช้ได้
  void _syncConnectionState() =>
      isOffline.value = !AppConfig.demoMode && !_session.socket.connected.value;

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
          _clearUndo();
        } else {
          // served ย้อนไม่ได้ (backend ไม่ยอม) — เสนอเลิกทำเฉพาะขั้นในครัว
          _offerUndo(
            KitchenStatusChange(item: item, from: item.status, to: next),
          );
          load(showLoader: false);
        }
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  /// ย้อนการเดินสถานะล่าสุดกลับหนึ่งขั้น
  Future<void> undoLast() async {
    final change = lastChange.value;
    if (change == null) return;
    _clearUndo();

    final result = await _updateItemStatus(
      UpdateItemStatusParams(
        orderId: change.item.orderId,
        itemId: change.item.id,
        status: change.from,
      ),
    );
    result.fold(
      onSuccess: (_) => load(showLoader: false),
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  void _offerUndo(KitchenStatusChange change) {
    _undoTimer?.cancel();
    lastChange.value = change;
    _undoTimer = Timer(undoWindow, _clearUndo);
  }

  void _clearUndo() {
    _undoTimer?.cancel();
    _undoTimer = null;
    lastChange.value = null;
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

/// การเดินสถานะหนึ่งครั้งในจอครัว — เก็บไว้ให้กด "เลิกทำ" ย้อนกลับได้
@immutable
class KitchenStatusChange {
  const KitchenStatusChange({
    required this.item,
    required this.from,
    required this.to,
  });

  final OrderItem item;
  final String from;
  final String to;
}
