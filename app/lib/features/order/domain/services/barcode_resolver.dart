import '../../../menu/domain/entities/menu_item.dart';

/// รูปแบบฉลากตาชั่ง EAN-13: [prefix] + PLU [pluDigits] หลัก + น้ำหนักกรัม [weightDigits] หลัก +
/// check digit 1 หลัก รวม 13 หลักพอดี (ร้านตั้งค่าได้ที่หน้าตั้งค่า — ดู docs/tickets/19-barcode-scale.md)
class ScaleLabelFormat {
  const ScaleLabelFormat({this.prefix = '20', this.pluDigits = 5});

  final String prefix;
  final int pluDigits;

  int get weightDigits => 12 - prefix.length - pluDigits;
}

/// ผลการสแกนหนึ่งครั้ง — หน้าจอเลือกว่าจะใส่ตะกร้าทันที เปิดหน้าชั่ง หรือแจ้งเตือน
sealed class ScanResult {
  const ScanResult();
}

/// สินค้าขายเป็นชิ้น (สแกนบาร์โค้ดบนขวด/ถุง) → ใส่ตะกร้า 1 ชิ้น
class ScannedUnitItem extends ScanResult {
  const ScannedUnitItem(this.item);
  final MenuItem item;
}

/// ฉลากจากตาชั่ง → รู้ทั้งสินค้าและน้ำหนัก ใส่ตะกร้าได้ทันทีโดยไม่ต้องพิมพ์อะไร
class ScannedWeighedItem extends ScanResult {
  const ScannedWeighedItem(this.item, this.weightGrams);
  final MenuItem item;
  final int weightGrams;
}

/// บาร์โค้ดธรรมดาของสินค้าขายตามน้ำหนัก (ไม่มีน้ำหนักในรหัส) → ต้องชั่งแล้วกรอกน้ำหนักก่อน
class ScannedNeedsWeighing extends ScanResult {
  const ScannedNeedsWeighing(this.item);
  final MenuItem item;
}

/// ฉลากตาชั่งที่ check digit ไม่ตรง — อ่านผิด/ฉลากขาด ห้ามเดาน้ำหนักจากรหัสที่เสีย
class ScanBadCheckDigit extends ScanResult {
  const ScanBadCheckDigit(this.code);
  final String code;
}

class ScanNotFound extends ScanResult {
  const ScanNotFound(this.code);
  final String code;
}

/// แปลงรหัสที่เครื่องสแกนพิมพ์เข้ามาเป็นสินค้า — ฟังก์ชันบริสุทธิ์ ทำงานในเครื่องทั้งหมด
///
/// ทำไมไม่ถาม backend: เครื่องสแกน USB/บลูทูธส่งรหัสเข้ามาเร็วเท่าคนพิมพ์ติดกัน 13 ตัว + Enter
/// รอบละไม่กี่ร้อยมิลลิวินาที เมนูโหลดมาอยู่ในเครื่องครบแล้ว และหน้าร้านต้องสแกนได้ต่อแม้เน็ตหลุด
/// (ดู docs/DECISIONS.md #49)
class BarcodeResolver {
  const BarcodeResolver._();

  /// ลำดับการจับคู่: บาร์โค้ดตรงทั้งรหัสก่อน (ร้านอาจลงทะเบียนรหัสขึ้นต้นด้วย 2 เป็นบาร์โค้ดธรรมดา
  /// ไว้เอง) แล้วค่อยลองอ่านเป็นฉลากตาชั่ง
  static ScanResult resolve(
    String raw,
    List<MenuItem> menu, {
    ScaleLabelFormat format = const ScaleLabelFormat(),
  }) {
    final code = raw.trim();
    if (code.isEmpty) return ScanNotFound(code);

    for (final item in menu) {
      if (item.barcode != null && item.barcode == code) {
        return item.soldByWeight
            ? ScannedNeedsWeighing(item)
            : ScannedUnitItem(item);
      }
    }

    if (_looksLikeScaleLabel(code, format)) {
      if (!isValidEan13(code)) return ScanBadCheckDigit(code);
      final pluStart = format.prefix.length;
      final weightStart = pluStart + format.pluDigits;
      final plu = int.parse(code.substring(pluStart, weightStart)).toString();
      final grams = int.parse(
        code.substring(weightStart, weightStart + format.weightDigits),
      );
      if (grams <= 0) return ScanNotFound(code);
      for (final item in menu) {
        if (item.soldByWeight && item.scalePlu == plu) {
          return ScannedWeighedItem(item, grams);
        }
      }
    }
    return ScanNotFound(code);
  }

  static bool _looksLikeScaleLabel(String code, ScaleLabelFormat format) =>
      code.length == 13 &&
      format.weightDigits >= 4 &&
      RegExp(r'^\d{13}$').hasMatch(code) &&
      code.startsWith(format.prefix);

  /// ตรวจ check digit ของ EAN-13 (หลักคี่คูณ 1 หลักคู่คูณ 3 ผลรวมรวม check digit ต้องหาร 10 ลงตัว)
  static bool isValidEan13(String code) {
    if (!RegExp(r'^\d{13}$').hasMatch(code)) return false;
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      final digit = code.codeUnitAt(i) - 48;
      sum += i.isOdd ? digit * 3 : digit;
    }
    return (10 - sum % 10) % 10 == code.codeUnitAt(12) - 48;
  }
}
