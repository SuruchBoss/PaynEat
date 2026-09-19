import 'package:flutter/widgets.dart';

final _boldPattern = RegExp(r'\*\*(.+?)\*\*');

/// ผู้ช่วย AI ตอบเป็นข้อความอิสระซึ่งบางครั้งใช้ **ตัวหนา** แบบ markdown — parse เฉพาะ bold นี้เอง
/// (ไม่ดึงแพ็กเกจ markdown เต็มรูปแบบมาใช้ เพราะ syntax อื่นๆ ไม่เคยปรากฏในคำตอบจริง)
List<InlineSpan> parseBoldMarkdown(String text) {
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in _boldPattern.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    spans.add(
      TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }
  return spans;
}
