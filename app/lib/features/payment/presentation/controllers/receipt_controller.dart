import 'package:get/get.dart';

import '../../../../core/services/session_service.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../order/domain/entities/order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/payment_usecases.dart';

/// เตรียมข้อมูลใบเสร็จสำหรับแสดง/พิมพ์
class ReceiptController extends GetxController {
  ReceiptController({
    required GetReceiptUseCase getReceipt,
    required RefundPaymentUseCase refundPayment,
    required SessionService session,
  }) : _getReceipt = getReceipt,
       _refundPayment = refundPayment,
       _session = session;

  final GetReceiptUseCase _getReceipt;
  final RefundPaymentUseCase _refundPayment;
  final SessionService _session;

  final Rxn<Order> order = Rxn<Order>();
  final Rxn<Receipt> receipt = Rxn<Receipt>();
  final RxBool isLoading = true.obs;
  final RxBool isRefunding = false.obs;
  final RxnString errorMessage = RxnString();

  bool get canRefund => _session.currentUser?.isManagement ?? false;

  late final int orderId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    orderId = (args is Map ? args['orderId'] as int? : null) ?? 0;
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _getReceipt(orderId);

    isLoading.value = false;
    result.fold(
      onSuccess: (data) {
        receipt.value = data.receipt;
        // Order.== เทียบแค่ id ต้องเคลียร์เป็น null ก่อนเพื่อบังคับให้ Rxn อัปเดตจริง
        // (ดู docs/CODING_STANDARDS.md หัวข้อ 3.5)
        order.value = null;
        order.value = data.order;
      },
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  /// ยอดที่ยังคืนได้ของ payment นี้ (หักรายการที่คืนไปแล้วก่อนหน้า)
  double refundableAmount(Payment payment) {
    final refunded = (receipt.value?.refunds ?? const [])
        .where((refund) => refund.paymentId == payment.id)
        .fold<double>(0, (sum, refund) => sum + refund.amount);
    return (payment.amount - refunded).clamp(0, payment.amount);
  }

  Future<void> submitRefund({
    required int paymentId,
    required double amount,
    required String reason,
  }) async {
    isRefunding.value = true;
    final result = await _refundPayment(
      RefundParams(paymentId: paymentId, amount: amount, reason: reason),
    );
    isRefunding.value = false;

    result.fold(
      onSuccess: (_) {
        AppDialogs.success('คืนเงินเรียบร้อย');
        load();
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }
}
