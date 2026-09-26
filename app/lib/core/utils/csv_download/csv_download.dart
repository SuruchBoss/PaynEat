// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

// ดาวน์โหลดไฟล์ CSV ให้ผู้ใช้ — เลือก implementation ตาม platform ตอน compile (ไม่มีให้เลือก
// runtime) เว็บใช้ csv_download_web.dart (Blob + `<a download>`) แพลตฟอร์มอื่นใช้
// csv_download_stub.dart (โยน UnsupportedError) เพราะฟีเจอร์นี้เจาะจงหน้าเว็บผู้ดูแลระบบ
export 'csv_download_stub.dart'
    if (dart.library.js_interop) 'csv_download_web.dart';
