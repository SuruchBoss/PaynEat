// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/localization/localized_name.dart';

/// โต๊ะที่ลูกค้าสแกน QR เข้ามา (ดู docs/tickets/17-qr-self-order.md) — มุมมองแบบตัดฟิลด์ของ
/// `Table` ที่พนักงานใช้ เหลือแค่สิ่งที่ลูกค้าต้องเห็นตอนสั่งอาหารเอง
class SelfOrderTable {
  const SelfOrderTable({
    required this.id,
    required this.name,
    required this.zone,
    this.zoneEn,
    this.zoneKo,
    this.branchName,
  });

  final int id;
  final String name;
  final String zone;
  final String? zoneEn;
  final String? zoneKo;
  final String? branchName;

  /// ชื่อโซนตามภาษาของ "ลูกค้า" ไม่ใช่ภาษาของร้าน
  ///
  /// หน้านี้เปิดบนมือถือของลูกค้าเอง เป็นหน้าเดียวที่คนนอกร้านเห็น
  /// ชื่อโซนที่หลุดเป็นภาษาอื่นตรงนี้จึงเสียภาพลักษณ์มากกว่าทุกหน้ารวมกัน
  /// (เคยหลุดจริง: แก้ displayZone ที่ผังโต๊ะของพนักงานแล้วแต่ตกหน้านี้ไว้)
  String get displayZone =>
      LocalizedName.pick(name: zone, nameEn: zoneEn, nameKo: zoneKo);
}
