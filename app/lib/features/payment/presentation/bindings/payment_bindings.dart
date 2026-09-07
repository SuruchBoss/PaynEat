import 'package:get/get.dart';

import '../../../order/domain/usecases/order_usecases.dart';
import '../../domain/usecases/payment_usecases.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/receipt_controller.dart';
import '../controllers/split_bill_controller.dart';

class CheckoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      CheckoutController(
        getOrder: Get.find<GetOrderUseCase>(),
        getSummary: Get.find<GetPaymentSummaryUseCase>(),
        pay: Get.find<PayOrderUseCase>(),
      ),
    );
  }
}

class ReceiptBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ReceiptController(getReceipt: Get.find<GetReceiptUseCase>()));
  }
}

class SplitBillBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      SplitBillController(
        getOrder: Get.find<GetOrderUseCase>(),
        getSplitPreview: Get.find<GetSplitPreviewUseCase>(),
        pay: Get.find<PayOrderUseCase>(),
      ),
    );
  }
}
