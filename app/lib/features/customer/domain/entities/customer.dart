/// ลูกค้า/สมาชิก + แต้มสะสม (ดู docs/tickets/09-customer-loyalty.md) — ผูกกับออเดอร์
/// แบบ optional เท่านั้น ลูกค้าทั่วไปไม่ต้องผูกก็สั่งอาหารได้ปกติ
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.pointsBalance = 0,
    this.createdAt,
    this.updatedAt,
    this.creditLimit = 0,
    this.creditTermDays = 30,
    this.taxId,
    this.address,
    this.creditOutstanding,
    this.creditAvailable,
  });

  final int id;
  final String name;
  final String phone;
  final String? email;
  final int pointsBalance;
  final String? createdAt;
  final String? updatedAt;

  /// ลูกค้าเครดิต/ขายส่ง (ดู docs/tickets/20-b2b-credit.md) — วงเงิน 0 = ขายเชื่อไม่ได้
  final double creditLimit;
  final int creditTermDays;
  final String? taxId;
  final String? address;

  /// ยอดหนี้ค้าง/วงเงินที่ยังเหลือ ณ ตอนดึง — มีเฉพาะตอนดึงรายละเอียดลูกค้ารายตัว
  /// (รายการค้นหาไม่คำนวณ เพื่อไม่ให้ค้นเบอร์โทรช้า)
  final double? creditOutstanding;
  final double? creditAvailable;

  bool get hasCreditAccount => creditLimit > 0;
}

/// ค่าที่ตั้งให้ลูกค้าเครดิตหนึ่งราย — taxId/address ว่าง = ล้างค่าเดิม
class CustomerCreditTerms {
  const CustomerCreditTerms({
    required this.creditLimit,
    required this.creditTermDays,
    this.taxId = '',
    this.address = '',
    this.email,
  });

  final double creditLimit;
  final int creditTermDays;
  final String taxId;
  final String address;

  /// อีเมลรับใบวางบิล/เอกสารลูกหนี้ (ดู docs/tickets/23-document-pdf-email.md) — null = ไม่แตะค่าเดิม
  /// '' = ล้างค่า
  final String? email;

  Map<String, dynamic> toJson() => {
    'creditLimit': creditLimit,
    'creditTermDays': creditTermDays,
    'taxId': taxId,
    'address': address,
    'email': ?email,
  };
}
