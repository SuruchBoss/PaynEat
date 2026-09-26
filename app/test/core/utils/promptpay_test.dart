// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/utils/promptpay.dart';

void main() {
  group('promptpay', () {
    test('crc16Ccitt ตรงกับ test vector มาตรฐานของ CRC-16/CCITT-FALSE', () {
      expect(crc16Ccitt('123456789').toRadixString(16).toUpperCase(), '29B1');
    });

    test(
      'buildPromptPayPayload: เบอร์โทร + ไม่ระบุยอด → static QR (POI method 11)',
      () {
        final payload = buildPromptPayPayload(promptPayId: '0812345678');
        expect(payload, startsWith('00020101021129'));
        expect(payload, contains('01130066812345678'));
        expect(payload, contains('A000000677010111'));
        expect(RegExp(r'6304[0-9A-F]{4}$').hasMatch(payload), isTrue);
      },
    );

    test(
      'buildPromptPayPayload: ระบุยอดเงิน → dynamic QR (POI method 12) พร้อม tag 54',
      () {
        final payload = buildPromptPayPayload(
          promptPayId: '0812345678',
          amount: 100,
        );
        expect(payload, startsWith('00020101021229'));
        expect(payload, contains('5406100.00'));
      },
    );

    test(
      'buildPromptPayPayload: เลขผู้เสียภาษี/บัตรประชาชน 13 หลัก ใช้ tag 02 ไม่แปลงเป็นเบอร์โทร',
      () {
        final payload = buildPromptPayPayload(
          promptPayId: '1234567890123',
          amount: 25.5,
        );
        expect(payload, contains('02131234567890123'));
        expect(payload, contains('540525.50'));
      },
    );

    test(
      'buildPromptPayPayload: ตัดอักขระที่ไม่ใช่ตัวเลขออกจาก promptPayId (เช่น ขีดคั่นเบอร์โทร)',
      () {
        final withDashes = buildPromptPayPayload(
          promptPayId: '081-234-5678',
          amount: 10,
        );
        final plain = buildPromptPayPayload(
          promptPayId: '0812345678',
          amount: 10,
        );
        expect(withDashes, plain);
      },
    );

    test(
      'buildPromptPayPayload: ตรงกับ payload ที่ backend คำนวณเป๊ะ (เทียบ golden value)',
      () {
        // golden value นี้คำนวณจาก backend/src/core/promptpay.js (ตัวอย่างเดียวกัน) —
        // ต้องตรงกันเป๊ะเพราะทั้งสองฝั่งอ้างอิงอัลกอริทึมเดียวกัน (ดู docs/DECISIONS.md #2)
        final payload = buildPromptPayPayload(
          promptPayId: '0812345678',
          amount: 100,
        );
        expect(
          payload,
          '00020101021229370016A000000677010111011300668123456785802TH53037645406100.006304BB8A',
        );
      },
    );

    test('buildPromptPayPayload: promptPayId ว่างเปล่าต้อง throw', () {
      expect(() => buildPromptPayPayload(promptPayId: ''), throwsArgumentError);
      expect(
        () => buildPromptPayPayload(promptPayId: '---'),
        throwsArgumentError,
      );
    });
  });
}
