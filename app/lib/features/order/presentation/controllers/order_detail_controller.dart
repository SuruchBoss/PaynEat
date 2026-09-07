import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/socket_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/usecases/result.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/usecases/order_usecases.dart';

/// จัดการหน้ารายละเอียดออเดอร์ 1 ใบ
class OrderDetailController extends GetxController {
  OrderDetailController({
    required GetOrderUseCase getOrder,
    required SendToKitchenUseCase sendToKitchen,
    required UpdateOrderItemUseCase updateItem,
    required RemoveOrderItemUseCase removeItem,
    required UpdateOrderItemStatusUseCase updateItemStatus,
    required ApplyDiscountUseCase applyDiscount,
    required CancelOrderUseCase cancelOrder,
    required SessionService session,
  }) : _getOrder = getOrder,
       _sendToKitchen = sendToKitchen,
       _updateItem = updateItem,
       _removeItem = removeItem,
       _updateItemStatus = updateItemStatus,
       _applyDiscount = applyDiscount,
       _cancelOrder = cancelOrder,
       _session = session;

  final GetOrderUseCase _getOrder;
  final SendToKitchenUseCase _sendToKitchen;
  final UpdateOrderItemUseCase _updateItem;
  final RemoveOrderItemUseCase _removeItem;
  final UpdateOrderItemStatusUseCase _updateItemStatus;
  final ApplyDiscountUseCase _applyDiscount;
  final CancelOrderUseCase _cancelOrder;
  final SessionService _session;

  final Rxn<Order> order = Rxn<Order>();
  final RxBool isLoading = true.obs;
  final RxBool isBusy = false.obs;
  final RxnString errorMessage = RxnString();

  late final int orderId;
  final List<VoidCallback> _unsubscribers = [];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    orderId = (args is Map ? args['orderId'] as int? : null) ?? 0;
    load();
    _listenToRealtimeUpdates();
  }

  @override
  void onClose() {
    for (final unsubscribe in _unsubscribers) {
      unsubscribe();
    }
    super.onClose();
  }

  bool get canManage => _session.currentUser?.isManagement ?? false;
  bool get canCollectPayment =>
      _session.currentUser?.canCollectPayment ?? false;

  Future<void> load({bool showLoader = true}) async {
    if (showLoader) isLoading.value = true;
    errorMessage.value = null;

    final result = await _getOrder(orderId);

    isLoading.value = false;
    result.fold(
      onSuccess: (data) => order.value = data,
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  Future<void> sendToKitchen() async {
    await _run(
      () => _sendToKitchen(orderId),
      successMessage: 'ส่งออเดอร์เข้าครัวแล้ว',
    );
  }

  Future<void> changeItemQuantity(OrderItem item, int quantity) async {
    await _run(
      () => _updateItem(
        UpdateOrderItemParams(
          orderId: orderId,
          itemId: item.id,
          quantity: quantity,
        ),
      ),
    );
  }

  Future<void> removeItem(OrderItem item) async {
    final confirmed = await AppDialogs.confirm(
      title: 'ลบรายการ',
      message: 'ต้องการลบ "${item.name}" ออกจากออเดอร์ใช่หรือไม่?',
      confirmLabel: 'ลบรายการ',
      destructive: true,
    );
    if (!confirmed) return;

    await _run(
      () =>
          _removeItem(RemoveOrderItemParams(orderId: orderId, itemId: item.id)),
      successMessage: 'ลบรายการแล้ว',
    );
  }

  /// เดินสถานะรายการไปขั้นถัดไป (รอทำ → กำลังทำ → พร้อมเสิร์ฟ → เสิร์ฟแล้ว)
  Future<void> advanceItemStatus(OrderItem item) async {
    final next = item.nextStatus;
    if (next == null) return;

    await _run(
      () => _updateItemStatus(
        UpdateItemStatusParams(orderId: orderId, itemId: item.id, status: next),
      ),
    );
  }

  Future<void> cancelItem(OrderItem item) async {
    final confirmed = await AppDialogs.confirm(
      title: 'ยกเลิกรายการ',
      message: 'ยกเลิก "${item.name}" ออกจากบิลใช่หรือไม่?',
      confirmLabel: 'ยกเลิกรายการ',
      destructive: true,
    );
    if (!confirmed) return;

    await _run(
      () => _updateItemStatus(
        UpdateItemStatusParams(
          orderId: orderId,
          itemId: item.id,
          status: OrderItemStatus.cancelled,
        ),
      ),
      successMessage: 'ยกเลิกรายการแล้ว',
    );
  }

  Future<void> applyDiscount({
    required String type,
    required double value,
  }) async {
    await _run(
      () => _applyDiscount(
        ApplyDiscountParams(orderId: orderId, type: type, value: value),
      ),
      successMessage: type == DiscountType.none
          ? 'ยกเลิกส่วนลดแล้ว'
          : 'ใช้ส่วนลดแล้ว',
    );
  }

  Future<void> cancelOrder(String reason) async {
    await _run(
      () => _cancelOrder(CancelOrderParams(orderId: orderId, reason: reason)),
      successMessage: 'ยกเลิกออเดอร์แล้ว',
    );
  }

  Future<void> addMoreItems() async {
    await Get.toNamed<void>(
      AppRoutes.newOrder,
      arguments: {'orderId': orderId, 'tableName': order.value?.tableName},
    );
    await load(showLoader: false);
  }

  Future<void> goToCheckout() async {
    await Get.toNamed<void>(
      AppRoutes.checkout,
      arguments: {'orderId': orderId},
    );
    await load(showLoader: false);
  }

  Future<void> openReceipt() =>
      Get.toNamed<void>(AppRoutes.receipt, arguments: {'orderId': orderId}) ??
      Future<void>.value();

  /// ห่อ action ทุกตัวให้จัดการ busy state และ error เหมือนกัน
  Future<void> _run(
    Future<Result<Order>> Function() action, {
    String? successMessage,
  }) async {
    isBusy.value = true;
    final result = await action();
    isBusy.value = false;

    result.fold(
      onSuccess: (data) {
        order.value = data;
        if (successMessage != null) AppDialogs.success(successMessage);
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  void _listenToRealtimeUpdates() {
    final socket = _session.socket;
    for (final event in [
      SocketEvents.orderUpdated,
      SocketEvents.orderItemUpdated,
    ]) {
      _unsubscribers.add(
        socket.on(event, (data) {
          // รีเฟรชเฉพาะเมื่อ event เป็นของออเดอร์ใบนี้
          final payload = data is Map ? data : const {};
          final eventOrderId = payload['id'] ?? payload['orderId'];
          if (eventOrderId == orderId) load(showLoader: false);
        }),
      );
    }
  }
}
