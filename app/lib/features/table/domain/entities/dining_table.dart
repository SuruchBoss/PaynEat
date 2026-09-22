import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/localized_name.dart';

/// สรุปออเดอร์ที่กำลังเปิดอยู่บนโต๊ะ (ใช้แสดงบนการ์ดผังโต๊ะ)
class TableOrderSummary {
  const TableOrderSummary({
    required this.id,
    required this.code,
    required this.status,
    required this.total,
    this.guestCount = 0,
    this.createdAt,
  });

  final int id;
  final String code;
  final String status;
  final double total;
  final int guestCount;
  final String? createdAt;
}

/// โต๊ะในร้าน
class DiningTable {
  const DiningTable({
    required this.id,
    required this.name,
    required this.zone,
    this.zoneEn,
    this.zoneKo,
    required this.seats,
    required this.status,
    this.isActive = true,
    this.currentOrder,
    this.qrToken,
  });

  final int id;
  final String name;
  final String zone;
  final String? zoneEn;
  final String? zoneKo;
  final int seats;
  final String status;
  final bool isActive;
  final TableOrderSummary? currentOrder;

  /// ใช้สร้างลิงก์/ภาพ QR ให้ลูกค้าสแกนสั่งเอง (ดู docs/tickets/17-qr-self-order.md) — null ได้
  /// เฉพาะข้อมูลเก่าก่อน migration เพิ่มคอลัมน์นี้ ของจริงหลัง migrate ต้องมีเสมอ
  final String? qrToken;

  /// ชื่อโซนตามภาษาปัจจุบัน (ดู [LocalizedName.pick])
  ///
  /// ใช้ทั้งหัวข้อกลุ่มและชิปตัวกรองบนผังโต๊ะ ต้องมาจากที่เดียวกัน ไม่งั้นกดชิป
  /// แล้วไม่ตรงกับกลุ่มไหนเลย
  String get displayZone =>
      LocalizedName.pick(name: zone, nameEn: zoneEn, nameKo: zoneKo);

  bool get isAvailable => status == TableStatus.available;
  bool get hasOpenOrder => currentOrder != null;
  String get statusLabel => TableStatus.label(status);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DiningTable && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
