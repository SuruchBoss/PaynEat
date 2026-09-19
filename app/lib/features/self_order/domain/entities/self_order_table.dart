/// โต๊ะที่ลูกค้าสแกน QR เข้ามา (ดู docs/tickets/17-qr-self-order.md) — มุมมองแบบตัดฟิลด์ของ
/// `Table` ที่พนักงานใช้ เหลือแค่สิ่งที่ลูกค้าต้องเห็นตอนสั่งอาหารเอง
class SelfOrderTable {
  const SelfOrderTable({
    required this.id,
    required this.name,
    required this.zone,
    this.branchName,
  });

  final int id;
  final String name;
  final String zone;
  final String? branchName;
}
