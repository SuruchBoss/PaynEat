import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/socket_client.dart';
import '../../../../core/services/session_service.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/order_usecases.dart';
import '../../../../core/utils/app_clock.dart';

/// รายการออเดอร์ พร้อมตัวกรองสถานะ
class OrderListController extends GetxController {
  OrderListController({
    required GetOrdersUseCase getOrders,
    required SessionService session,
  }) : _getOrders = getOrders,
       _session = session;

  final GetOrdersUseCase _getOrders;
  final SessionService _session;

  final RxList<Order> orders = <Order>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxnString statusFilter = RxnString();
  final RxBool activeOnly = true.obs;

  final List<VoidCallback> _unsubscribers = [];

  static List<({String? value, String label})> get filters => [
    (value: null, label: 'order_filter_active'.tr),
    (value: OrderStatus.open, label: 'order_filter_not_sent'.tr),
    (value: OrderStatus.inKitchen, label: 'order_filter_in_kitchen'.tr),
    (value: OrderStatus.served, label: OrderStatus.label(OrderStatus.served)),
    (value: OrderStatus.paid, label: 'order_filter_paid_today'.tr),
    (
      value: OrderStatus.cancelled,
      label: OrderStatus.label(OrderStatus.cancelled),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
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

  Future<void> load({bool showLoader = true}) async {
    if (showLoader) isLoading.value = true;
    errorMessage.value = null;

    final status = statusFilter.value;
    final today = AppClock.now().toIso8601String().substring(0, 10);

    final result = await _getOrders(
      OrderListFilter(
        status: status,
        activeOnly: status == null ? true : null,
        // ออเดอร์ที่ปิดแล้วดูเฉพาะของวันนี้ก็พอ ไม่งั้นรายการยาวเกินใช้งานจริง
        dateFrom: status == OrderStatus.paid || status == OrderStatus.cancelled
            ? today
            : null,
        limit: 50,
      ),
    );

    isLoading.value = false;
    result.fold(
      onSuccess: (data) => orders.assignAll(data.orders),
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  void setFilter(String? status) {
    statusFilter.value = status;
    load();
  }

  Future<void> openOrder(Order order) async {
    await Get.toNamed<void>(
      AppRoutes.orderDetail,
      arguments: {'orderId': order.id},
    );
    await load(showLoader: false);
  }

  void _listenToRealtimeUpdates() {
    final socket = _session.socket;
    for (final event in [
      SocketEvents.orderCreated,
      SocketEvents.orderUpdated,
      SocketEvents.orderPaid,
    ]) {
      _unsubscribers.add(socket.on(event, (_) => load(showLoader: false)));
    }
  }
}
