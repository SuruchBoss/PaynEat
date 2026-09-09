import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../order/domain/entities/order.dart';
import '../../../order/domain/usecases/order_usecases.dart';
import '../../../shift/domain/usecases/shift_usecases.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/payment_usecases.dart';

/// หน้าจอเก็บเงิน — รองรับจ่ายครบทีเดียวและแยกจ่ายหลายช่องทาง
class CheckoutController extends GetxController {
  CheckoutController({
    required GetOrderUseCase getOrder,
    required GetPaymentSummaryUseCase getSummary,
    required PayOrderUseCase pay,
    required GetCurrentShiftUseCase getCurrentShift,
  }) : _getOrder = getOrder,
       _getSummary = getSummary,
       _pay = pay,
       _getCurrentShift = getCurrentShift;

  final GetOrderUseCase _getOrder;
  final GetPaymentSummaryUseCase _getSummary;
  final PayOrderUseCase _pay;
  final GetCurrentShiftUseCase _getCurrentShift;

  final Rxn<Order> order = Rxn<Order>();
  final Rxn<PaymentSummary> summary = Rxn<PaymentSummary>();
  final RxBool hasOpenShift = true.obs;
  final RxBool isLoading = true.obs;
  final RxBool isPaying = false.obs;
  final RxnString errorMessage = RxnString();
  final RxString method = PaymentMethod.cash.obs;
  final RxDouble amount = 0.0.obs;
  final RxDouble received = 0.0.obs;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController receivedController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();

  late final int orderId;

  /// ปุ่มลัดธนบัตรที่ใช้บ่อยในร้าน
  static const List<double> quickCashOptions = [100, 500, 1000];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    orderId = (args is Map ? args['orderId'] as int? : null) ?? 0;
    load();
  }

  @override
  void onClose() {
    amountController.dispose();
    receivedController.dispose();
    referenceController.dispose();
    super.onClose();
  }

  double get remaining => summary.value?.remaining ?? 0;
  bool get isCash => method.value == PaymentMethod.cash;

  /// เงินทอน = เงินที่รับมา - ยอดที่จ่ายรอบนี้
  double get change {
    if (!isCash) return 0;
    final value = received.value - amount.value;
    return value > 0 ? double.parse(value.toStringAsFixed(2)) : 0;
  }

  bool get canPay {
    if (!hasOpenShift.value) return false;
    if (amount.value <= 0 || amount.value > remaining + 0.001) return false;
    if (isCash && received.value + 0.001 < amount.value) return false;
    return true;
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final shiftResult = await _getCurrentShift();
    hasOpenShift.value = shiftResult.dataOrNull != null;

    final results = await Future.wait([
      _getOrder(orderId),
      _getSummary(orderId),
    ]);

    isLoading.value = false;
    results[0].fold(
      onSuccess: (data) {
        // Order.== เทียบแค่ id ต้องเคลียร์เป็น null ก่อนเพื่อบังคับให้ Rxn อัปเดตจริง
        // (ดู docs/CODING_STANDARDS.md หัวข้อ 3.5) — โหลดซ้ำหลัง submit() ที่จ่ายไม่ครบ
        // ใช้ order id เดิมเสมอ
        order.value = null;
        order.value = data as Order;
      },
      onFailure: (failure) => errorMessage.value = failure.message,
    );
    results[1].fold(
      onSuccess: (data) {
        summary.value = data as PaymentSummary;
        setAmount(summary.value!.remaining);
      },
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  void selectMethod(String value) {
    method.value = value;
    if (value != PaymentMethod.cash) {
      setReceived(amount.value);
    }
  }

  void setAmount(double value) {
    final rounded = double.parse(value.toStringAsFixed(2));
    amount.value = rounded;
    amountController.text = rounded.toStringAsFixed(2);
    if (received.value < rounded) setReceived(rounded);
  }

  void onAmountChanged(String value) {
    amount.value = double.tryParse(value.trim()) ?? 0;
  }

  void setReceived(double value) {
    received.value = value;
    receivedController.text = value.toStringAsFixed(2);
  }

  void onReceivedChanged(String value) {
    received.value = double.tryParse(value.trim()) ?? 0;
  }

  /// ปัดขึ้นเป็นหลักร้อยถัดไป เช่น ยอด 176.55 → เสนอปุ่ม 200
  double get roundedUpSuggestion {
    final target = remaining;
    if (target <= 0) return 0;
    return (target / 100).ceil() * 100;
  }

  Future<void> submit() async {
    if (!canPay) return;

    isPaying.value = true;
    final result = await _pay(
      PayParams(
        orderId: orderId,
        method: method.value,
        amount: amount.value,
        received: isCash ? received.value : null,
        reference: referenceController.text.trim(),
      ),
    );
    isPaying.value = false;

    result.fold(
      onSuccess: (data) {
        if (data.result.isFullyPaid) {
          AppDialogs.success('ปิดบิลเรียบร้อย');
          Get.offNamed<void>(
            AppRoutes.receipt,
            arguments: {'orderId': orderId},
          );
        } else {
          AppDialogs.success(
            'รับชำระแล้ว คงเหลือ ${data.result.remaining.toStringAsFixed(2)} บาท',
          );
          referenceController.clear();
          load();
        }
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }
}
