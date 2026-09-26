// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../domain/entities/self_order_table.dart';

class SelfOrderTableModel extends SelfOrderTable {
  const SelfOrderTableModel({
    required super.id,
    required super.name,
    required super.zone,
    super.zoneEn,
    super.zoneKo,
    super.branchName,
  });

  /// json คือ data['table'] ที่ backend คืนมา — branchName แยกอยู่คนละ key ที่ระดับบนสุดของ
  /// response (ดู public-order.service.js#getTable) จึงรับเข้ามาแยกต่างหาก
  factory SelfOrderTableModel.fromJson(
    Map<String, dynamic> json, {
    String? branchName,
  }) => SelfOrderTableModel(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    zone: json['zone'] as String? ?? '',
    zoneEn: json['zoneEn'] as String?,
    zoneKo: json['zoneKo'] as String?,
    branchName: branchName,
  );
}
