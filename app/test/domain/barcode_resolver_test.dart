// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/order/domain/services/barcode_resolver.dart';

/// เติม check digit ให้รหัส 12 หลักเป็น EAN-13 ที่ถูกต้อง — คำนวณเองในเทสต์ ไม่เรียกโค้ดที่กำลังทดสอบ
String ean13(String twelve) {
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final digit = int.parse(twelve[i]);
    sum += i.isOdd ? digit * 3 : digit;
  }
  return '$twelve${(10 - sum % 10) % 10}';
}

/// ฉลากตาชั่งของร้านเนื้อ (ดู docs/tickets/19-barcode-scale.md)
void main() {
  const ribeye = MenuItem(
    id: 1,
    categoryId: 8,
    name: 'ริบอาย',
    price: 890,
    soldByWeight: true,
    scalePlu: '101',
  );
  const porkBelly = MenuItem(
    id: 2,
    categoryId: 8,
    name: 'สามชั้น',
    price: 220,
    soldByWeight: true,
    scalePlu: '7',
    barcode: '8850000000017',
  );
  const sauce = MenuItem(
    id: 3,
    categoryId: 2,
    name: 'ซอสจิ้มจุ่ม',
    price: 59,
    barcode: '8851234567898',
  );
  const menu = [ribeye, porkBelly, sauce];

  group('BarcodeResolver', () {
    test('บาร์โค้ดสินค้าชิ้น → ใส่ตะกร้า 1 ชิ้น', () {
      final result = BarcodeResolver.resolve(' 8851234567898 ', menu);

      expect(result, isA<ScannedUnitItem>());
      expect((result as ScannedUnitItem).item, sauce);
    });

    test('ฉลากตาชั่ง 20 + PLU 00101 + 00485 กรัม → ริบอาย 485 กรัม', () {
      final label = ean13('200010100485');

      final result = BarcodeResolver.resolve(label, menu);

      expect(result, isA<ScannedWeighedItem>());
      final weighed = result as ScannedWeighedItem;
      expect(weighed.item, ribeye);
      expect(weighed.weightGrams, 485);
    });

    test('PLU ที่มีเลข 0 นำหน้าบนฉลากจับคู่กับ PLU ที่เก็บแบบไม่มี 0', () {
      final result = BarcodeResolver.resolve(ean13('200000701250'), menu);

      expect(result, isA<ScannedWeighedItem>());
      expect((result as ScannedWeighedItem).item, porkBelly);
      expect(result.weightGrams, 1250);
    });

    test('check digit ผิด → ไม่เดาน้ำหนักจากรหัสที่อ่านผิด', () {
      final good = ean13('200010100485');
      final broken =
          '${good.substring(0, 12)}${(int.parse(good[12]) + 1) % 10}';

      expect(BarcodeResolver.resolve(broken, menu), isA<ScanBadCheckDigit>());
    });

    test('บาร์โค้ดธรรมดาของสินค้าชั่งน้ำหนัก → ต้องชั่งก่อน', () {
      final result = BarcodeResolver.resolve('8850000000017', menu);

      expect(result, isA<ScannedNeedsWeighing>());
      expect((result as ScannedNeedsWeighing).item, porkBelly);
    });

    test('PLU ที่ไม่มีในเมนู / รหัสแปลก / น้ำหนัก 0 → ไม่พบสินค้า', () {
      expect(
        BarcodeResolver.resolve(ean13('200099900485'), menu),
        isA<ScanNotFound>(),
      );
      expect(BarcodeResolver.resolve('hello', menu), isA<ScanNotFound>());
      expect(BarcodeResolver.resolve('', menu), isA<ScanNotFound>());
      expect(
        BarcodeResolver.resolve(ean13('200010100000'), menu),
        isA<ScanNotFound>(),
      );
    });

    test(
      'ร้านตั้ง prefix/จำนวนหลัก PLU เองได้ — 2 + PLU 4 หลัก + น้ำหนัก 6 หลัก',
      () {
        const format = ScaleLabelFormat(prefix: '2', pluDigits: 4);
        final label = ean13('201010012345');

        final result = BarcodeResolver.resolve(label, menu, format: format);

        expect(result, isA<ScannedWeighedItem>());
        expect((result as ScannedWeighedItem).weightGrams, 12345);
        expect(
          BarcodeResolver.resolve(label, menu),
          isA<ScanNotFound>(),
          reason:
              'รูปแบบค่าเริ่มต้น (20 + 5 + 5) อ่านฉลากนี้เป็น PLU 10100 ซึ่งไม่มี',
        );
      },
    );

    test(
      'ฉลากตาชั่งจับคู่เฉพาะเมนูขายตามน้ำหนัก ไม่ใช่เมนูชิ้นที่บังเอิญมี PLU',
      () {
        const oddUnit = MenuItem(
          id: 9,
          categoryId: 1,
          name: 'ของชิ้น',
          price: 10,
          scalePlu: '101',
        );

        final result = BarcodeResolver.resolve(ean13('200010100485'), const [
          oddUnit,
        ]);

        expect(result, isA<ScanNotFound>());
      },
    );

    test('บาร์โค้ดที่ลงทะเบียนไว้ตรงตัวชนะการอ่านเป็นฉลากตาชั่ง', () {
      final label = ean13('200010100485');
      final registered = MenuItem(
        id: 10,
        categoryId: 2,
        name: 'ของที่รหัสขึ้นต้นด้วย 20',
        price: 35,
        barcode: label,
      );

      final result = BarcodeResolver.resolve(label, [ribeye, registered]);

      expect(result, isA<ScannedUnitItem>());
      expect((result as ScannedUnitItem).item, registered);
    });

    test('isValidEan13', () {
      expect(BarcodeResolver.isValidEan13('8851234567895'), isFalse);
      expect(BarcodeResolver.isValidEan13(ean13('885123456789')), isTrue);
      expect(BarcodeResolver.isValidEan13('12345'), isFalse);
      expect(BarcodeResolver.isValidEan13('abcdefghijklm'), isFalse);
    });
  });
}
