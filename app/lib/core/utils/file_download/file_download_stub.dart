// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/// implementation เริ่มต้น (non-web) — ยังไม่มีที่เก็บไฟล์ที่ใช้ร่วมกันได้ทุกแพลตฟอร์ม
bool get isFileDownloadSupported => false;

void downloadBytes(String filename, List<int> bytes, String mimeType) {
  throw UnsupportedError('ดาวน์โหลดไฟล์รองรับเฉพาะบนเว็บ');
}
