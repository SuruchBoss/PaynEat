import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/store_settings.dart';
import '../../domain/usecases/settings_usecases.dart';

/// ตั้งค่าร้าน — ชื่อร้าน, VAT, Service Charge
class SettingsController extends GetxController {
  SettingsController({
    required GetSettingsUseCase getSettings,
    required UpdateSettingsUseCase updateSettings,
  }) : _getSettings = getSettings,
       _updateSettings = updateSettings;

  final GetSettingsUseCase _getSettings;
  final UpdateSettingsUseCase _updateSettings;

  final Rx<StoreSettings> settings = StoreSettings.fallback.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool vatIncluded = false.obs;

  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController vatController = TextEditingController();
  final TextEditingController serviceChargeController = TextEditingController();
  final TextEditingController storeTaxIdController = TextEditingController();
  final TextEditingController storeAddressController = TextEditingController();
  final TextEditingController storeBranchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    storeNameController.dispose();
    vatController.dispose();
    serviceChargeController.dispose();
    storeTaxIdController.dispose();
    storeAddressController.dispose();
    storeBranchController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _getSettings();

    isLoading.value = false;
    result.fold(
      onSuccess: (data) {
        settings.value = data;
        storeNameController.text = data.storeName;
        vatController.text = data.vatPercent.toStringAsFixed(0);
        serviceChargeController.text = data.serviceChargePercent
            .toStringAsFixed(0);
        vatIncluded.value = data.vatIncluded;
        storeTaxIdController.text = data.storeTaxId ?? '';
        storeAddressController.text = data.storeAddress ?? '';
        storeBranchController.text = data.storeBranch ?? '';
      },
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  Future<void> save() async {
    final vatPercent = double.tryParse(vatController.text.trim());
    final servicePercent = double.tryParse(serviceChargeController.text.trim());

    if (vatPercent == null || vatPercent < 0 || vatPercent > 100) {
      AppDialogs.error('settings_vat_range_error'.tr);
      return;
    }
    if (servicePercent == null || servicePercent < 0 || servicePercent > 100) {
      AppDialogs.error('settings_service_charge_range_error'.tr);
      return;
    }

    isSaving.value = true;
    final result = await _updateSettings(
      UpdateSettingsParams(
        storeName: storeNameController.text.trim(),
        vatRate: vatPercent / 100,
        serviceChargeRate: servicePercent / 100,
        vatIncluded: vatIncluded.value,
        storeTaxId: storeTaxIdController.text.trim(),
        storeAddress: storeAddressController.text.trim(),
        storeBranch: storeBranchController.text.trim(),
      ),
    );
    isSaving.value = false;

    result.fold(
      onSuccess: (data) {
        settings.value = data;
        AppDialogs.success('settings_saved_success'.tr);
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }
}
