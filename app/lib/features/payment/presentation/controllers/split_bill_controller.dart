import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../order/domain/entities/order.dart';
import '../../../order/domain/entities/order_item.dart';
import '../../../order/domain/usecases/order_usecases.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/payment_usecases.dart';

/// แยกบิลรายการอาหาร — เลือกเมนูที่จะจ่ายรอบนี้ ดูยอดล่วงหน้า แล้วชำระเป็นก้อนๆ
/// จนกว่าจะครบทุกรายการ (แต่ละรายการจ่ายได้แค่ครั้งเดียว กันเลือกซ้ำ)
class SplitBillController extends GetxController {
  SplitBillController({
    required GetOrderUseCase getOrder,
    required GetSplitPreviewUseCase getSplitPreview,
    required PayOrderUseCase pay,
  }) : _getOrder = getOrder,
       _getSplitPreview = getSplitPreview,
       _pay = pay;

  final GetOrderUseCase _getOrder;
  final GetSplitPreviewUseCase _getSplitPreview;
  final PayOrderUseCase _pay;

  final Rxn<Order> order = Rxn<Order>();
  final Rxn<SplitPreview> preview = Rxn<SplitPreview>();
  final RxSet<int> selectedItemIds = <int>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isPaying = false.obs;
  final RxnString errorMessage = RxnString();
  final RxString method = PaymentMethod.cash.obs;
  final RxDouble received = 0.0.obs;

  final TextEditingController receivedController = TextEditingController();

  late final int orderId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    orderId = (args is Map ? args['orderId'] as int? : null) ?? 0;
    load();
  }

  @override
  void onClose() {
    receivedController.dispose();
    super.onClose();
  }

  List<OrderItem> get unpaidItems =>
      order.value?.activeItems
          .where((item) => !item.isPaid)
          .toList(growable: false) ??
      const [];

  bool get isCash => method.value == PaymentMethod.cash;

  double get change {
    final total = preview.value?.total;
    if (!isCash || total == null) return 0;
    final value = received.value - total;
    return value > 0 ? double.parse(value.toStringAsFixed(2)) : 0;
  }

  bool get canPay {
    final total = preview.value?.total;
    if (selectedItemIds.isEmpty || total == null) return false;
    if (isCash && received.value + 0.001 < total) return false;
    return true;
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _getOrder(orderId);

    isLoading.value = false;
    result.fold(
      onSuccess: (data) {
        // Order.== เทียบแค่ id ต้องเคลียร์เป็น null ก่อนเพื่อบังคับให้ Rxn อัปเดตจริง
        // (ดู docs/CODING_STANDARDS.md หัวข้อ 3.5)
        order.value = null;
        order.value = data;
      },
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  void selectMethod(String value) => method.value = value;

  void setReceived(double value) {
    received.value = value;
    receivedController.text = value.toStringAsFixed(2);
  }

  void onReceivedChanged(String value) =>
      received.value = double.tryParse(value.trim()) ?? 0;

  Future<void> toggleItem(int itemId) async {
    if (!selectedItemIds.add(itemId)) selectedItemIds.remove(itemId);
    await _refreshPreview();
  }

  Future<void> _refreshPreview() async {
    if (selectedItemIds.isEmpty) {
      preview.value = null;
      return;
    }

    final result = await _getSplitPreview(
      SplitPreviewParams(orderId: orderId, itemIds: selectedItemIds.toList()),
    );

    result.fold(
      onSuccess: (data) {
        preview.value = data;
        if (received.value < data.total) setReceived(data.total);
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  Future<void> submit() async {
    if (!canPay) return;

    isPaying.value = true;
    final result = await _pay(
      PayParams(
        orderId: orderId,
        method: method.value,
        itemIds: selectedItemIds.toList(),
        received: isCash ? received.value : null,
      ),
    );
    isPaying.value = false;

    result.fold(
      onSuccess: (data) {
        // Order.== เทียบแค่ id ต้องเคลียร์เป็น null ก่อนเพื่อบังคับให้ Rxn อัปเดตจริง
        // (ดู docs/CODING_STANDARDS.md หัวข้อ 3.5)
        order.value = null;
        order.value = data.order;
        selectedItemIds.clear();
        preview.value = null;
        setReceived(0);

        if (data.result.isFullyPaid) {
          AppDialogs.success('payment_bill_closed_success'.tr);
          Get.offNamed<void>(
            AppRoutes.receipt,
            arguments: {'orderId': orderId},
          );
        } else {
          AppDialogs.success(
            'payment_partial_paid_success'.trParams({
              'amount': data.result.remaining.toStringAsFixed(2),
            }),
          );
        }
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }
}
