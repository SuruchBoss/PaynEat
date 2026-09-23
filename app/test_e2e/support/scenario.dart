import 'package:flutter_test/flutter_test.dart';

/// ลำดับขั้นของสถานการณ์เดียวที่ต่อกันเป็นเรื่องเดียว (เช่น หนึ่งวันทำงานของร้าน)
///
/// แต่ละขั้นเป็น `test` แยกกัน ผลออกมาจึงอ่านได้ว่าขั้นไหนผ่าน/ล้ม แต่ขั้นหลังพึ่งผลของขั้นก่อน
/// (ออเดอร์ที่เปิดไว้ กะที่เปิดอยู่ ฯลฯ) — ถ้าขั้นไหนล้ม ขั้นถัดไปจะล้มพร้อมบอกตรง ๆ ว่าไม่ได้รัน
/// เพราะขั้นไหน แทนที่จะพ่น `LateInitializationError` ให้ต้องไปเดาเองว่าต้นเหตุอยู่ตรงไหน
class Scenario {
  String? _brokenAt;

  bool get hasFailed => _brokenAt != null;

  void step(String name, Future<void> Function() body) {
    test(name, () async {
      final brokenAt = _brokenAt;
      if (brokenAt != null) fail('ไม่ได้รัน — ขั้น "$brokenAt" ล้มไปก่อนแล้ว');
      try {
        await body();
      } catch (_) {
        _brokenAt ??= name;
        rethrow;
      }
    });
  }
}

/// เทียบจำนวนเงินระดับสตางค์ — backend เก็บเป็นสตางค์ (จำนวนเต็ม) แล้วแปลงเป็นบาทตอนส่งออก
/// ฝั่งแอปคำนวณด้วย double จึงเผื่อคลาดได้ไม่เกินครึ่งสตางค์เท่านั้น
Matcher baht(num amount) => closeTo(amount.toDouble(), 0.005);
