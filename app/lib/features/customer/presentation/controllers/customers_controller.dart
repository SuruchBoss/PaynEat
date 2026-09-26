// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'dart:async';

import 'package:get/get.dart';

import '../../domain/entities/customer.dart';
import '../../domain/usecases/customer_usecases.dart';

/// รายชื่อลูกค้า/สมาชิกทั้งหมด (admin/manager) — ค้นหาแล้วกดดูประวัติการซื้อ/แต้มสะสม
/// รายคนได้ (ดู docs/tickets/09-customer-loyalty.md)
class CustomersController extends GetxController {
  CustomersController({required SearchCustomersUseCase searchCustomers})
    : _searchCustomers = searchCustomers;

  final SearchCustomersUseCase _searchCustomers;

  final RxList<Customer> customers = <Customer>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxString query = ''.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  /// ดีบาวซ์ก่อนยิงค้นหาจริง กันยิง API ถี่เกินไปตอนพิมพ์
  void search(String value) {
    query.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), load);
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _searchCustomers(
      SearchCustomersParams(
        search: query.value.trim().isEmpty ? null : query.value.trim(),
        limit: 50,
      ),
    );

    isLoading.value = false;
    result.fold(
      onSuccess: (data) => customers.assignAll(data.customers),
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }
}
