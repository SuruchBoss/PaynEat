/// น้ำหนักหนึ่งค่าจากตาชั่งต่อสาย (ดู docs/tickets/22-live-scale-camera-scan.md)
class ScaleReading {
  const ScaleReading({
    required this.grams,
    required this.stable,
    this.overload = false,
    this.at,
  });

  /// กรัมเต็ม เหมือน `order_items.weight_grams` — ติดลบได้ถ้าหักภาชนะเกิน
  final int grams;

  /// ตัวเลขนิ่งแล้ว (ตาชั่งบอกเอง) — ระหว่างของยังแกว่งห้ามใช้ ไม่งั้นคิดเงินผิด
  final bool stable;
  final bool overload;
  final DateTime? at;

  /// ใช้คิดเงินได้: นิ่ง ไม่เกินพิกัด และอยู่ในช่วงที่ backend รับ (1–99,999 กรัม)
  bool get usable => stable && !overload && grams >= 1 && grams <= 99999;
}

/// สถานะตาชั่งที่เซิร์ฟเวอร์ร้านต่ออยู่ — [reading] เป็น null เมื่อยังไม่มีค่าหรือค่าเก่าเกินไป
class ScaleStatus {
  const ScaleStatus({
    required this.enabled,
    required this.driver,
    required this.connected,
    this.error,
    this.reading,
  });

  /// ร้านไม่ได้ต่อตาชั่ง (SCALE_DRIVER=off) หรืออ่านสถานะไม่ได้ — กล่องชั่งน้ำหนักแสดงช่องกรอกอย่างเดียว
  static const ScaleStatus off = ScaleStatus(
    enabled: false,
    driver: 'off',
    connected: false,
  );

  final bool enabled;

  /// tcp / serial / simulator
  final String driver;
  final bool connected;
  final String? error;
  final ScaleReading? reading;

  bool get isSimulator => driver == 'simulator';
}
