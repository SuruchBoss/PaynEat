// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

// ดาวน์โหลดไฟล์ไบต์ (PDF เอกสารลูกหนี้ — docs/tickets/23-document-pdf-email.md) ให้ผู้ใช้ เลือก
// implementation ตาม platform ตอน compile เหมือน csv_download: เว็บใช้ Blob + `<a download>`
// แพลตฟอร์มอื่นยังไม่รองรับ (ปุ่มดาวน์โหลดถูกซ่อน ใช้ "ส่งอีเมล" แทน)
export 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_web.dart';
