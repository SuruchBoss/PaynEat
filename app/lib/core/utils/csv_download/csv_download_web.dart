import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// ดาวน์โหลดไฟล์ CSV บนเว็บ — สร้าง Blob URL ชั่วคราวแล้วกดลิงก์ดาวน์โหลดให้เอง
/// (ไม่มีให้ผู้ใช้เห็น element นี้เลย ลบทิ้งทันทีหลังกด)
bool get isCsvDownloadSupported => true;

void downloadCsv(String filename, String content) {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
