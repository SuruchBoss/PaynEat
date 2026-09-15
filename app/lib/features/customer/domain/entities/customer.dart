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
  });

  final int id;
  final String name;
  final String phone;
  final String? email;
  final int pointsBalance;
  final String? createdAt;
  final String? updatedAt;
}
