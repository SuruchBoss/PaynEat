import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/shift.dart';
import '../../domain/usecases/shift_usecases.dart';

/// หน้าจอเปิด/ปิดกะของแคชเชียร์ — ใช้กระทบยอดเงินสดตอนสิ้นกะ
class ShiftController extends GetxController {
  ShiftController({
    required GetCurrentShiftUseCase getCurrent,
    required OpenShiftUseCase openShift,
    required CloseShiftUseCase closeShift,
    required GetShiftHistoryUseCase getHistory,
  }) : _getCurrent = getCurrent,
       _openShift = openShift,
       _closeShift = closeShift,
       _getHistory = getHistory;

  final GetCurrentShiftUseCase _getCurrent;
  final OpenShiftUseCase _openShift;
  final CloseShiftUseCase _closeShift;
  final GetShiftHistoryUseCase _getHistory;

  final Rxn<Shift> current = Rxn<Shift>();
  final Rxn<Shift> lastClosed = Rxn<Shift>();
  final RxList<Shift> history = <Shift>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();

  final TextEditingController openingCashController = TextEditingController();
  final TextEditingController countedCashController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    openingCashController.dispose();
    countedCashController.dispose();
    noteController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final results = await Future.wait([_getCurrent(), _getHistory()]);

    isLoading.value = false;
    results[0].fold(
      onSuccess: (data) => current.value = data as Shift?,
      onFailure: (failure) => errorMessage.value = failure.message,
    );
    results[1].fold(
      onSuccess: (data) {
        history
          ..clear()
          ..addAll(data as List<Shift>);
      },
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  Future<void> submitOpen() async {
    final openingCash = double.tryParse(openingCashController.text.trim());
    if (openingCash == null || openingCash < 0) {
      AppDialogs.error('shift_invalid_opening_cash'.tr);
      return;
    }

    isSubmitting.value = true;
    final result = await _openShift(openingCash);
    isSubmitting.value = false;

    result.fold(
      onSuccess: (shift) {
        current.value = shift;
        lastClosed.value = null;
        openingCashController.clear();
        AppDialogs.success('shift_open_success'.tr);
        load();
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  Future<void> submitClose() async {
    final shift = current.value;
    if (shift == null) return;
    final countedCash = double.tryParse(countedCashController.text.trim());
    if (countedCash == null || countedCash < 0) {
      AppDialogs.error('shift_invalid_counted_cash'.tr);
      return;
    }

    final confirmed = await AppDialogs.confirm(
      title: 'shift_close_confirm_title'.tr,
      message: 'shift_close_confirm_message'.tr,
    );
    if (!confirmed) return;

    isSubmitting.value = true;
    final result = await _closeShift(
      CloseShiftParams(
        id: shift.id,
        countedCash: countedCash,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      ),
    );
    isSubmitting.value = false;

    result.fold(
      onSuccess: (closed) {
        current.value = null;
        lastClosed.value = closed;
        countedCashController.clear();
        noteController.clear();
        AppDialogs.success('shift_close_success'.tr);
        load();
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  void startNewShift() {
    lastClosed.value = null;
  }
}
