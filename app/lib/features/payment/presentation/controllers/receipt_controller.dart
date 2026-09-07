import 'package:get/get.dart';

import '../../../order/domain/entities/order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/payment_usecases.dart';

/// เตรียมข้อมูลใบเสร็จสำหรับแสดง/พิมพ์
class ReceiptController extends GetxController {
  ReceiptController({required GetReceiptUseCase getReceipt}) : _getReceipt = getReceipt;

  final GetReceiptUseCase _getReceipt;

  final Rxn<Order> order = Rxn<Order>();
  final Rxn<Receipt> receipt = Rxn<Receipt>();
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

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
        order.value = data.order;
      },
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }
}
