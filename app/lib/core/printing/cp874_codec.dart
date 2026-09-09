import 'dart:convert';
import 'dart:typed_data';

/// ตารางรหัสอักษรไทย CP874 (Windows-874 / เทียบเท่า TIS-620 ในช่วงอักษรไทย) สำหรับส่งให้
/// เครื่องพิมพ์ ESC/POS
///
/// `esc_pos_utils_plus` เข้ารหัสข้อความด้วย [Codec] ที่ส่งเข้าไปตอนสร้าง `Generator`
/// (ค่าเริ่มต้นคือ `latin1` ซึ่งไม่รองรับอักษรไทย) ช่วงอักษรไทยใน Unicode
/// (U+0E01-U+0E5B) ถูกออกแบบให้ตรงกับ TIS-620 แบบเลื่อนค่าคงที่ +0xA0 พอดี จึงแปลงไป-กลับ
/// ได้ตรง ๆ โดยไม่ต้องพึ่งตารางแมปเต็มรูปแบบ
class Cp874Codec extends Encoding {
  const Cp874Codec();

  static const int thaiUnicodeStart = 0x0E01;
  static const int thaiUnicodeEnd = 0x0E5B;
  static const int thaiByteOffset = 0xA0;

  @override
  String get name => 'cp874';

  @override
  Converter<String, List<int>> get encoder => const Cp874Encoder();

  @override
  Converter<List<int>, String> get decoder => const Cp874Decoder();
}

class Cp874Encoder extends Converter<String, List<int>> {
  const Cp874Encoder();

  @override
  Uint8List convert(String input) {
    final bytes = Uint8List(input.length);
    for (var i = 0; i < input.length; i++) {
      bytes[i] = _encodeChar(input.codeUnitAt(i));
    }
    return bytes;
  }

  int _encodeChar(int code) {
    if (code < 0x80) return code;
    if (code >= Cp874Codec.thaiUnicodeStart &&
        code <= Cp874Codec.thaiUnicodeEnd) {
      return code - 0x0E00 + Cp874Codec.thaiByteOffset;
    }
    if (code == 0x20AC) {
      return 0x80; // เครื่องหมายยูโร (ตำแหน่งเฉพาะของ Windows-874)
    }
    return 0x3F; // '?' แทนอักขระที่แปลงไม่ได้ กันคำสั่งพิมพ์พัง
  }
}

class Cp874Decoder extends Converter<List<int>, String> {
  const Cp874Decoder();

  @override
  String convert(List<int> input) {
    final buffer = StringBuffer();
    for (final byte in input) {
      if (byte < 0x80) {
        buffer.writeCharCode(byte);
      } else if (byte == 0x80) {
        buffer.writeCharCode(0x20AC);
      } else if (byte >= 0xA1 && byte <= 0xFB) {
        buffer.writeCharCode(byte - Cp874Codec.thaiByteOffset + 0x0E00);
      } else {
        buffer.writeCharCode(0xFFFD);
      }
    }
    return buffer.toString();
  }
}
