import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/printing/receipt_printer_service.dart';
import 'package:payneat_pos/core/services/printer_settings_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/features/settings/domain/entities/printer_profile.dart';
import 'package:payneat_pos/features/settings/presentation/controllers/printer_settings_controller.dart';

void main() {
  group('PrinterSettingsController', () {
    test('onInit เติมค่าฟอร์มจากการตั้งค่าที่บันทึกไว้ก่อนหน้า', () async {
      final storage = StorageService.memory();
      final settingsService = PrinterSettingsService(storage: storage);
      await settingsService.save(
        const PrinterProfile(
          ipAddress: '192.168.1.99',
          port: 9100,
          paperWidthMm: 58,
          enabled: true,
        ),
      );

      final controller = PrinterSettingsController(
        settingsService: settingsService,
        printerService: ReceiptPrinterService(),
      );
      controller.onInit();

      expect(controller.ipController.text, '192.168.1.99');
      expect(controller.portController.text, '9100');
      expect(controller.enabled.value, isTrue);
      expect(controller.paperWidthMm.value, 58);

      controller.onClose();
    });

    test(
      'ค่าเริ่มต้นเมื่อยังไม่เคยตั้งค่าเครื่องพิมพ์ — ปิดใช้งานและพอร์ตเป็น 9100',
      () {
        final controller = PrinterSettingsController(
          settingsService: PrinterSettingsService(
            storage: StorageService.memory(),
          ),
          printerService: ReceiptPrinterService(),
        );
        controller.onInit();

        expect(controller.ipController.text, isEmpty);
        expect(controller.portController.text, '9100');
        expect(controller.enabled.value, isFalse);

        controller.onClose();
      },
    );

    // save() และ testPrint() แตะ AppDialogs ทุกทาง (ทั้งกรอกไม่ผ่าน/สำเร็จ/ล้มเหลว)
    // จึงไม่ครอบคลุมในเทสต์ระดับ unit นี้ (ดู docs/CODING_STANDARDS.md — รูปแบบเดียวกับ
    // submitRefund ใน receipt_controller_test.dart)
  });
}
