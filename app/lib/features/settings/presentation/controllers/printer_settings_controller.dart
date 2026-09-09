import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/printing/receipt_printer_service.dart';
import '../../../../core/services/printer_settings_service.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/printer_profile.dart';

/// ตั้งค่า/ทดสอบเครื่องพิมพ์ใบเสร็จของเครื่องนี้ (แยกจาก [SettingsController] เพราะเป็นค่า
/// เฉพาะอุปกรณ์ ไม่ใช่ค่าของร้านที่ซิงก์กับเซิร์ฟเวอร์)
class PrinterSettingsController extends GetxController {
  PrinterSettingsController({
    required PrinterSettingsService settingsService,
    required ReceiptPrinterService printerService,
  }) : _settingsService = settingsService,
       _printerService = printerService;

  final PrinterSettingsService _settingsService;
  final ReceiptPrinterService _printerService;

  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final RxBool enabled = false.obs;
  final RxInt paperWidthMm = 80.obs;
  final RxBool isTesting = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _applyToForm(_settingsService.profile);
  }

  @override
  void onClose() {
    ipController.dispose();
    portController.dispose();
    super.onClose();
  }

  void _applyToForm(PrinterProfile profile) {
    ipController.text = profile.ipAddress;
    portController.text = profile.port.toString();
    enabled.value = profile.enabled;
    paperWidthMm.value = profile.paperWidthMm;
  }

  PrinterProfile? _draftProfile() {
    final ip = ipController.text.trim();
    final port = int.tryParse(portController.text.trim());
    if (enabled.value && ip.isEmpty) {
      AppDialogs.error('กรุณากรอก IP เครื่องพิมพ์');
      return null;
    }
    if (port == null || port <= 0 || port > 65535) {
      AppDialogs.error('พอร์ตไม่ถูกต้อง');
      return null;
    }
    return PrinterProfile(
      ipAddress: ip,
      port: port,
      paperWidthMm: paperWidthMm.value,
      enabled: enabled.value,
    );
  }

  Future<void> save() async {
    final draft = _draftProfile();
    if (draft == null) return;

    isSaving.value = true;
    await _settingsService.save(draft);
    isSaving.value = false;
    AppDialogs.success('บันทึกการตั้งค่าเครื่องพิมพ์แล้ว');
  }

  Future<void> testPrint() async {
    final draft = _draftProfile();
    if (draft == null) return;

    isTesting.value = true;
    final result = await _printerService.printTestPage(draft);
    isTesting.value = false;

    result.fold(
      onSuccess: (_) => AppDialogs.success('พิมพ์ทดสอบสำเร็จ'),
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }
}
