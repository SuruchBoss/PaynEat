import 'package:get/get.dart';

import '../../../../core/printing/receipt_printer_service.dart';
import '../../../../core/services/printer_settings_service.dart';
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
    required PrinterSettingsService printerSettings,
    required ReceiptPrinterService printerService,
  }) : _getReceipt = getReceipt,
       _refundPayment = refundPayment,
       _session = session,
       _printerSettings = printerSettings,
       _printerService = printerService;

  final GetReceiptUseCase _getReceipt;
  final RefundPaymentUseCase _refundPayment;
  final SessionService _session;
  final PrinterSettingsService _printerSettings;
  final ReceiptPrinterService _printerService;

  final Rxn<Order> order = Rxn<Order>();
  final Rxn<Receipt> receipt = Rxn<Receipt>();
  final RxBool isLoading = true.obs;
  final RxBool isRefunding = false.obs;
  final RxBool isPrinting = false.obs;
  final RxnString errorMessage = RxnString();

  bool get canRefund => _session.currentUser?.isManagement ?? false;

  /// มีเครื่องพิมพ์จริงที่ตั้งค่า/เปิดใช้งานไว้ของเครื่องนี้หรือไม่ — ใช้แค่ปรับ label/ไอคอน
  /// ของปุ่มพิมพ์ ไม่ได้ใช้กันการกด (กดได้เสมอ ให้ [printReceipt] แจ้งเหตุผลเองถ้าพิมพ์ไม่ได้)
  bool get printerConfigured => _printerSettings.profile.isConfigured;

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
        AppDialogs.success('payment_refund_success'.tr);
        load();
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  /// สั่งพิมพ์ใบเสร็จออกเครื่องพิมพ์ความร้อนจริง — ไม่มีเครื่องพิมพ์ตั้งค่าไว้ หรือพิมพ์บนเว็บ
  /// ก็ยังกดได้ตามปกติ เพียงแต่จะได้ข้อความแจ้งเหตุผลแทนแล้วให้ใช้ใบเสร็จบนจอต่อไป
  Future<void> printReceipt() async {
    final currentOrder = order.value;
    final currentReceipt = receipt.value;
    if (currentOrder == null || currentReceipt == null) return;

    isPrinting.value = true;
    final result = await _printerService.printReceipt(
      printer: _printerSettings.profile,
      order: currentOrder,
      receipt: currentReceipt,
    );
    isPrinting.value = false;

    result.fold(
      onSuccess: (_) => AppDialogs.success('payment_print_success'.tr),
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }
}
