// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/// แปลง list ของ object เป็น CSV string (RFC 4180 พื้นฐาน) — mirror ของ
/// `backend/src/core/csv.js` ตัวต่อตัว (ต้องแก้คู่กันเสมอ ดู docs/DECISIONS.md #2) เพราะ
/// Demo Mode ไม่มี backend จริงให้เรียกตอน export audit log (ดู
/// docs/tickets/14-financial-audit-trail.md)
library;

String _escapeCsvField(Object? value) {
  final str = value?.toString() ?? '';
  if (str.contains(RegExp(r'[",\n\r]'))) {
    return '"${str.replaceAll('"', '""')}"';
  }
  return str;
}

/// columns: [(label, value(row))] — เรียงตามลำดับที่ต้องการให้ขึ้นในไฟล์
String toCsv<T>(
  List<T> rows,
  List<({String label, Object? Function(T row) value})> columns,
) {
  final header = columns.map((col) => _escapeCsvField(col.label)).join(',');
  final lines = rows.map(
    (row) => columns.map((col) => _escapeCsvField(col.value(row))).join(','),
  );
  // ขึ้นต้นด้วย UTF-8 BOM กัน Excel เปิดแล้วอักษรไทยเพี้ยน (Excel เดาเป็น ANSI ถ้าไม่มี BOM)
  final bom = String.fromCharCode(0xfeff);
  return bom + [header, ...lines].join('\r\n');
}
