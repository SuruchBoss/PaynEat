/// ค่าตั้งค่าของร้าน (ใช้คิดบิลและแสดงบนใบเสร็จ)
class StoreSettings {
  const StoreSettings({
    required this.storeName,
    required this.currency,
    required this.vatRate,
    required this.serviceChargeRate,
    required this.vatIncluded,
  });

  final String storeName;
  final String currency;
  final double vatRate;
  final double serviceChargeRate;
  final bool vatIncluded;

  double get vatPercent => vatRate * 100;
  double get serviceChargePercent => serviceChargeRate * 100;

  static const StoreSettings fallback = StoreSettings(
    storeName: 'PaynEat Restaurant',
    currency: 'THB',
    vatRate: 0.07,
    serviceChargeRate: 0.1,
    vatIncluded: false,
  );
}
