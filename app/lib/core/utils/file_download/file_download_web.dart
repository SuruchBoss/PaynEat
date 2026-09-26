// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// ดาวน์โหลดไฟล์บนเว็บ — สร้าง Blob URL ชั่วคราวแล้วกดลิงก์ดาวน์โหลดให้เอง
bool get isFileDownloadSupported => true;

void downloadBytes(String filename, List<int> bytes, String mimeType) {
  final blob = web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
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
