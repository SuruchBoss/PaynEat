// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:get/get.dart';

import '../../domain/entities/receivable.dart';
import '../../domain/usecases/receivable_usecases.dart';

/// รายชื่อลูกค้าเครดิตพร้อมยอดค้าง/เกินกำหนด (ดู docs/tickets/20-b2b-credit.md)
class ReceivablesController extends GetxController {
  ReceivablesController({required GetReceivableCustomersUseCase getCustomers})
    : _getCustomers = getCustomers;

  final GetReceivableCustomersUseCase _getCustomers;

  final RxList<ReceivableSummary> summaries = <ReceivableSummary>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  double get totalOutstanding =>
      summaries.fold(0, (sum, row) => sum + row.outstanding);

  double get totalOverdue => summaries.fold(0, (sum, row) => sum + row.overdue);

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    final result = await _getCustomers();
    isLoading.value = false;
    result.fold(
      onSuccess: summaries.assignAll,
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }
}
