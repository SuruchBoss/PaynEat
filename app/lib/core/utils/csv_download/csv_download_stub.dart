// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/// implementation เริ่มต้น (non-web) — export CSV เป็นฟีเจอร์เฉพาะหน้าเว็บผู้ดูแลระบบ
/// (ดู README หัวข้อ "🖥️ ผู้ดูแลระบบ (เว็บ)") แพลตฟอร์มอื่นยังไม่รองรับการดาวน์โหลดไฟล์
bool get isCsvDownloadSupported => false;

void downloadCsv(String filename, String content) {
  throw UnsupportedError('ดาวน์โหลดไฟล์ CSV รองรับเฉพาะบนเว็บ');
}
