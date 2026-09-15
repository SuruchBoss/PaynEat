/// ค่าตั้งค่าของร้าน (ใช้คิดบิลและแสดงบนใบเสร็จ)
class StoreSettings {
  const StoreSettings({
    required this.storeName,
    required this.currency,
    required this.vatRate,
    required this.serviceChargeRate,
    required this.vatIncluded,
    this.storeTaxId,
    this.storeAddress,
    this.storeBranch,
    this.pointsEarnRateBaht = 25,
    this.pointsRedeemValueBaht = 1,
    this.promptPayId,
  });

  final String storeName;
  final String currency;
  final double vatRate;
  final double serviceChargeRate;
  final bool vatIncluded;

  /// ข้อมูลร้านสำหรับออกใบกำกับภาษี (ดู docs/tickets/07-tax-invoice.md) — เป็น null ได้
  /// จนกว่าร้านจะตั้งค่าเอง (ร้านที่ไม่ได้จด VAT ไม่จำเป็นต้องมี)
  final String? storeTaxId;
  final String? storeAddress;
  final String? storeBranch;

  /// แต้มสะสม (ดู docs/tickets/09-customer-loyalty.md) — จ่ายครบกี่บาทได้ 1 แต้ม /
  /// มูลค่า 1 แต้มตอนใช้แลกส่วนลด เป็นบาท
  final double pointsEarnRateBaht;
  final double pointsRedeemValueBaht;

  /// เลขพร้อมเพย์ของร้าน (เบอร์โทร/เลขบัตรประชาชน/เลขผู้เสียภาษี) — ต้องตั้งก่อนช่องทางจ่าย
  /// "qr" จะแสดง QR จริงได้ (ดู docs/tickets/16-promptpay-qr.md) เป็น null ได้จนกว่าจะตั้งค่าเอง
  final String? promptPayId;

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
