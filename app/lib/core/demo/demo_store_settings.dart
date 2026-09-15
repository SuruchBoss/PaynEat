part of 'demo_store.dart';

// ------------------------------------------------------------ settings ---
extension DemoStoreSettings on DemoStore {
  /// mirror ของ settings.service.js#update — เฉพาะ VAT/ค่าบริการ (ตัวเลขที่กระทบยอดขาย
  /// ทุกบิลทันที) ที่ต้อง log เป็น audit log ส่วนฟิลด์อื่น (ชื่อร้าน ที่อยู่ ฯลฯ) ไม่ต้อง
  /// (ดู docs/tickets/08-audit-log.md)
  Map<String, dynamic> updateSettings(
    Map<String, dynamic> changes, {
    int? actorId,
  }) {
    final previousVatRate = settings['vatRate'] as double;
    final previousServiceChargeRate = settings['serviceChargeRate'] as double;

    changes.forEach((key, value) => settings[key] = value);

    final newVatRate = changes['vatRate'] as double?;
    final newServiceChargeRate = changes['serviceChargeRate'] as double?;
    final rateChanges = <String>[];
    if (newVatRate != null && newVatRate != previousVatRate) {
      rateChanges.add('VAT $previousVatRate% → $newVatRate%');
    }
    if (newServiceChargeRate != null &&
        newServiceChargeRate != previousServiceChargeRate) {
      rateChanges.add(
        'ค่าบริการ $previousServiceChargeRate% → $newServiceChargeRate%',
      );
    }
    if (rateChanges.isNotEmpty) {
      _logAudit(
        actorId: actorId,
        action: 'settings.update',
        entityType: 'settings',
        summary: 'แก้ไขการตั้งค่า: ${rateChanges.join(', ')}',
        metadata: {
          'previousVatRate': previousVatRate,
          'newVatRate': newVatRate,
          'previousServiceChargeRate': previousServiceChargeRate,
          'newServiceChargeRate': newServiceChargeRate,
        },
      );
    }

    return settings;
  }
}
