import 'package:get/get.dart';

import '../../../order/domain/entities/order.dart';
import '../../../order/domain/usecases/order_usecases.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/customer_usecases.dart';

/// ประวัติการซื้อ/แต้มสะสมของลูกค้ารายคน (admin/manager)
/// ใช้ endpoint `GET /orders?customerId=` เดิมแทนการทำ endpoint แยก
/// (ดู docs/DECISIONS.md)
class CustomerDetailController extends GetxController {
  CustomerDetailController({
    required GetCustomerUseCase getCustomer,
    required GetOrdersUseCase getOrders,
  }) : _getCustomer = getCustomer,
       _getOrders = getOrders;

  final GetCustomerUseCase _getCustomer;
  final GetOrdersUseCase _getOrders;

  final Rxn<Customer> customer = Rxn<Customer>();
  final RxList<Order> orders = <Order>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  late final int customerId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    customerId = (args is Map ? args['customerId'] as int? : null) ?? 0;
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final results = await Future.wait([
      _getCustomer(customerId),
      _getOrders(OrderListFilter(customerId: customerId, limit: 50)),
    ]);

    isLoading.value = false;
    results[0].fold(
      onSuccess: (data) => customer.value = data as Customer,
      onFailure: (failure) => errorMessage.value = failure.message,
    );
    results[1].fold(
      onSuccess: (data) {
        final typed = data as ({List<Order> orders, int total});
        orders.assignAll(typed.orders);
      },
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }
}
