import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/features/ai_assistant/presentation/utils/bold_markdown.dart';

String _textOf(InlineSpan span) => (span as TextSpan).text ?? '';
bool _isBold(InlineSpan span) =>
    (span as TextSpan).style?.fontWeight == FontWeight.w700;

void main() {
  group('parseBoldMarkdown', () {
    test('ข้อความธรรมดาไม่มี ** ได้ span เดียวไม่ตัวหนา', () {
      final spans = parseBoldMarkdown('ยอดขายวันนี้ 641.47 บาท');

      expect(spans, hasLength(1));
      expect(_textOf(spans.first), 'ยอดขายวันนี้ 641.47 บาท');
      expect(_isBold(spans.first), isFalse);
    });

    test('แปลง **ข้อความ** ตรงกลางเป็น span ตัวหนาแยกจากข้อความรอบข้าง', () {
      final spans = parseBoldMarkdown(
        'เมนูขายดีที่สุดคือ **ผัดกะเพราหมูสับ** ขายได้ 8 จาน',
      );

      expect(spans, hasLength(3));
      expect(_textOf(spans[0]), 'เมนูขายดีที่สุดคือ ');
      expect(_isBold(spans[0]), isFalse);
      expect(_textOf(spans[1]), 'ผัดกะเพราหมูสับ');
      expect(_isBold(spans[1]), isTrue);
      expect(_textOf(spans[2]), ' ขายได้ 8 จาน');
      expect(_isBold(spans[2]), isFalse);
    });

    test('รองรับตัวหนาหลายจุดในข้อความเดียวกัน', () {
      final spans = parseBoldMarkdown('**อันดับ 1** และ **อันดับ 2**');

      expect(spans.map(_textOf), ['อันดับ 1', ' และ ', 'อันดับ 2']);
      expect(spans.map(_isBold), [true, false, true]);
    });

    test('ไม่มีตัวหนาเลยเมื่อ ** ไม่ครบคู่', () {
      final spans = parseBoldMarkdown('ราคา ** ยังไม่ปิด');

      expect(spans, hasLength(1));
      expect(_textOf(spans.first), 'ราคา ** ยังไม่ปิด');
      expect(_isBold(spans.first), isFalse);
    });
  });
}
