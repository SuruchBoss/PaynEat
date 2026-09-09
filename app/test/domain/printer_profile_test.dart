import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/features/settings/domain/entities/printer_profile.dart';

void main() {
  group('PrinterProfile', () {
    test('isConfigured เป็นจริงเมื่อเปิดใช้งานและมี IP เท่านั้น', () {
      expect(PrinterProfile.empty.isConfigured, isFalse);
      expect(
        const PrinterProfile(
          ipAddress: '192.168.1.1',
          enabled: false,
        ).isConfigured,
        isFalse,
      );
      expect(
        const PrinterProfile(ipAddress: '', enabled: true).isConfigured,
        isFalse,
      );
      expect(
        const PrinterProfile(
          ipAddress: '192.168.1.1',
          enabled: true,
        ).isConfigured,
        isTrue,
      );
    });

    test('toJson/fromJson ไป-กลับได้ค่าเดิมครบทุกฟิลด์', () {
      const profile = PrinterProfile(
        ipAddress: '192.168.1.50',
        port: 9100,
        paperWidthMm: 58,
        enabled: true,
      );

      final restored = PrinterProfile.fromJson(profile.toJson());

      expect(restored.ipAddress, profile.ipAddress);
      expect(restored.port, profile.port);
      expect(restored.paperWidthMm, profile.paperWidthMm);
      expect(restored.enabled, profile.enabled);
    });

    test('fromJson ใช้ค่าเริ่มต้นเมื่อ key หายไป (กันข้อมูลเก่าพัง)', () {
      final restored = PrinterProfile.fromJson(const {});

      expect(restored.ipAddress, '');
      expect(restored.port, 9100);
      expect(restored.paperWidthMm, 80);
      expect(restored.enabled, isFalse);
    });

    test('copyWith แก้เฉพาะฟิลด์ที่ระบุ', () {
      const profile = PrinterProfile(ipAddress: '10.0.0.1', enabled: true);
      final updated = profile.copyWith(port: 9101);

      expect(updated.ipAddress, '10.0.0.1');
      expect(updated.enabled, isTrue);
      expect(updated.port, 9101);
    });
  });
}
