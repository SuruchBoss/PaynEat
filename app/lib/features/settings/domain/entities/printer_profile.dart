/// การตั้งค่าเครื่องพิมพ์ใบเสร็จของ "เครื่องนี้"
///
/// ผูกกับอุปกรณ์ที่แคชเชียร์ใช้งาน ไม่ใช่ของร้านโดยรวมแบบ [StoreSettings] เพราะแต่ละ
/// เครื่อง cashier ต่อเครื่องพิมพ์คนละตัวได้ — เก็บไว้ใน local storage ของเครื่องเท่านั้น
/// ไม่ส่งขึ้นเซิร์ฟเวอร์
class PrinterProfile {
  const PrinterProfile({
    this.ipAddress = '',
    this.port = 9100,
    this.paperWidthMm = 80,
    this.enabled = false,
  });

  /// IP ของเครื่องพิมพ์บนวง LAN/WiFi เดียวกับเครื่อง cashier
  final String ipAddress;

  /// พอร์ตดิบสำหรับพิมพ์ ESC/POS — เครื่องพิมพ์ความร้อนส่วนใหญ่ใช้ 9100 เป็นค่าเริ่มต้น
  final int port;

  /// ความกว้างกระดาษ (มม.) — 58 หรือ 80 มม. เป็นขนาดที่ใช้กันทั่วไปในร้านอาหาร
  final int paperWidthMm;

  /// เปิดใช้งานเครื่องพิมพ์นี้หรือไม่ (ปิดไว้ = ใช้ใบเสร็จบนจอเหมือนเดิม)
  final bool enabled;

  bool get isConfigured => enabled && ipAddress.trim().isNotEmpty;

  static const PrinterProfile empty = PrinterProfile();

  PrinterProfile copyWith({
    String? ipAddress,
    int? port,
    int? paperWidthMm,
    bool? enabled,
  }) => PrinterProfile(
    ipAddress: ipAddress ?? this.ipAddress,
    port: port ?? this.port,
    paperWidthMm: paperWidthMm ?? this.paperWidthMm,
    enabled: enabled ?? this.enabled,
  );

  Map<String, dynamic> toJson() => {
    'ipAddress': ipAddress,
    'port': port,
    'paperWidthMm': paperWidthMm,
    'enabled': enabled,
  };

  factory PrinterProfile.fromJson(Map<String, dynamic> json) => PrinterProfile(
    ipAddress: json['ipAddress'] as String? ?? '',
    port: json['port'] as int? ?? 9100,
    paperWidthMm: json['paperWidthMm'] as int? ?? 80,
    enabled: json['enabled'] as bool? ?? false,
  );
}
