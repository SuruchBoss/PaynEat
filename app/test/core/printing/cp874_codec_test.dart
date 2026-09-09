import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/printing/cp874_codec.dart';

void main() {
  const codec = Cp874Codec();

  group('Cp874Codec', () {
    test('เข้ารหัส ASCII ตรงตัว (ไม่แปลง)', () {
      final bytes = codec.encode('A1: 100.00');
      expect(bytes, 'A1: 100.00'.codeUnits);
    });

    test('เข้ารหัสอักษรไทยด้วยค่าคงที่ +0xA0 ตามมาตรฐาน TIS-620/CP874', () {
      // ก (U+0E01) ต้องได้ 0xA1 ตามตาราง TIS-620/CP874 มาตรฐาน
      expect(codec.encode('ก'), [0xA1]);
      // ๛ (U+0E5B) ตัวสุดท้ายของบล็อกไทยใน Unicode ต้องได้ 0xFB
      expect(codec.encode('๛'), [0xFB]);
      // ฿ (U+0E3F เครื่องหมายบาท) ต้องได้ 0xDF
      expect(codec.encode('฿'), [0xDF]);
    });

    test('เข้ารหัสข้อความไทยผสมอังกฤษ/ตัวเลข/สัญลักษณ์ได้ครบทุกตัวอักษร', () {
      const text = 'ทดสอบ ก-ฮ ๐-๙ ฿100.00';
      final bytes = codec.encode(text);
      expect(bytes.length, text.length);
    });

    test('ถอดรหัสกลับได้ข้อความเดิม (round-trip)', () {
      const text = 'ใบเสร็จรับเงิน โต๊ะ A1 รวม ฿107.00';
      final bytes = codec.encode(text);
      expect(codec.decode(bytes), text);
    });

    test('อักขระที่แปลงไม่ได้ (เช่น อักษรจีน) ถูกแทนด้วย ? แทนที่จะ throw', () {
      final bytes = codec.encode('中文');
      expect(bytes, [0x3F, 0x3F]);
    });
  });
}
