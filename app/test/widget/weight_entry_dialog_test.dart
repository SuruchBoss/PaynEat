import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/features/order/presentation/widgets/weight_entry_dialog.dart';

/// พนักงานพิมพ์น้ำหนักตามที่หน้าจอตาชั่งแสดง (กิโลกรัม) — แปลงเป็นกรัมเต็มก่อนส่ง backend
/// (ดู docs/tickets/18-sell-by-weight.md)
void main() {
  group('WeightEntryDialog.parseGrams', () {
    test('กิโลกรัมทศนิยม → กรัม', () {
      expect(WeightEntryDialog.parseGrams('0.485'), 485);
      expect(WeightEntryDialog.parseGrams(' 1.2 '), 1200);
      expect(WeightEntryDialog.parseGrams('2'), 2000);
    });

    test('รับจุลภาคแทนจุดทศนิยมได้ (คีย์บอร์ดบางภาษา)', () {
      expect(WeightEntryDialog.parseGrams('1,25'), 1250);
    });

    test('ปัดเศษกรัมให้เป็นจำนวนเต็ม', () {
      expect(WeightEntryDialog.parseGrams('0.4856'), 486);
    });

    test('นอกช่วง 1–99,999 กรัม หรืออ่านไม่ได้ → null', () {
      expect(WeightEntryDialog.parseGrams(''), isNull);
      expect(WeightEntryDialog.parseGrams('abc'), isNull);
      expect(WeightEntryDialog.parseGrams('0'), isNull);
      expect(WeightEntryDialog.parseGrams('0.0004'), isNull);
      expect(WeightEntryDialog.parseGrams('100'), isNull);
      expect(WeightEntryDialog.parseGrams('-1'), isNull);
    });
  });
}
