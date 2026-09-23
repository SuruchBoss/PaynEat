import 'package:get/get.dart';

import '../../../../core/services/session_service.dart';
import '../../domain/usecases/customer_usecases.dart';
import '../../../order/domain/usecases/order_usecases.dart';
import '../controllers/customer_detail_controller.dart';

class CustomerDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      CustomerDetailController(
        getCustomer: Get.find<GetCustomerUseCase>(),
        getOrders: Get.find<GetOrdersUseCase>(),
        updateCredit: Get.find<UpdateCustomerCreditUseCase>(),
        session: Get.find<SessionService>(),
      ),
    );
  }
}
