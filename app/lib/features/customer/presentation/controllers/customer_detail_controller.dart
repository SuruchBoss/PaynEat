// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:get/get.dart';

import '../../../../core/services/session_service.dart';
import '../../../../core/widgets/app_dialogs.dart';
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
    UpdateCustomerCreditUseCase? updateCredit,
    SessionService? session,
  }) : _getCustomer = getCustomer,
       _getOrders = getOrders,
       _updateCredit = updateCredit,
       _session = session;

  final GetCustomerUseCase _getCustomer;
  final GetOrdersUseCase _getOrders;
  final UpdateCustomerCreditUseCase? _updateCredit;
  final SessionService? _session;

  final Rxn<Customer> customer = Rxn<Customer>();
  final RxList<Order> orders = <Order>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  late final int customerId;

  /// ตั้งวงเงิน/เครดิตเทอมได้เฉพาะผู้จัดการขึ้นไป (ตรงกับ PATCH /customers/:id/credit)
  bool get canEditCredit =>
      _updateCredit != null && (_session?.currentUser?.isManagement ?? false);

  /// เปิดบัญชีลูกหนี้ได้ทั้งแคชเชียร์ (รับชำระหนี้) และผู้จัดการ
  bool get canOpenStatement => _session?.currentUser?.canHandleCredit ?? false;

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

  /// บันทึกวงเงินเครดิต — คืน true ถ้าสำเร็จ (ข้อความผิดพลาดโชว์ให้แล้ว)
  Future<bool> saveCredit(CustomerCreditTerms terms) async {
    final updateCredit = _updateCredit;
    if (updateCredit == null) return false;
    final result = await updateCredit(
      UpdateCustomerCreditParams(id: customerId, terms: terms),
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      AppDialogs.error(failure.message);
      return false;
    }
    AppDialogs.success('customer_credit_saved'.tr);
    await load();
    return true;
  }
}
