// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/utils/csv.dart';

void main() {
  group('toCsv', () {
    const columns = [
      (label: 'ชื่อ', value: _nameOf),
      (label: 'จำนวน', value: _amountOf),
    ];

    test('ขึ้นต้นด้วย UTF-8 BOM แล้วตามด้วย header', () {
      final csv = toCsv(<Map<String, Object?>>[], columns);
      expect(csv, '${String.fromCharCode(0xfeff)}ชื่อ,จำนวน');
    });

    test('แปลงแถวข้อมูลเป็นบรรทัดคั่นด้วย comma คั่นบรรทัดด้วย \\r\\n', () {
      final rows = [
        {'name': 'ส้มตำ', 'amount': 80},
        {'name': 'ผัดไทย', 'amount': 60},
      ];
      final csv = toCsv(rows, columns);
      final expected =
          '${String.fromCharCode(0xfeff)}ชื่อ,จำนวน\r\nส้มตำ,80\r\nผัดไทย,60';
      expect(csv, expected);
    });

    test(
      'field ที่มี comma/quote/newline ต้องถูก quote และ escape ให้ถูกต้อง',
      () {
        final rows = [
          {'name': 'เมนู, พิเศษ', 'amount': 1},
          {'name': 'มี "คำพูด"', 'amount': 2},
          {'name': 'ขึ้นบรรทัด\nใหม่', 'amount': 3},
        ];
        final csv = toCsv(rows, columns);
        expect(csv, contains('"เมนู, พิเศษ",1'));
        expect(csv, contains('"มี ""คำพูด""",2'));
        expect(csv, contains('"ขึ้นบรรทัด\nใหม่",3'));
      },
    );

    test('ค่า null แปลงเป็นสตริงว่าง ไม่ใช่ "null"', () {
      final rows = [
        {'name': null, 'amount': null},
      ];
      final csv = toCsv(rows, columns);
      expect(csv, endsWith(','));
      expect(csv, isNot(contains('null')));
    });
  });
}

Object? _nameOf(Map<String, Object?> row) => row['name'];
Object? _amountOf(Map<String, Object?> row) => row['amount'];
