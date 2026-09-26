// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/// สาขา (ดู docs/tickets/11-multi-branch.md) — ผู้ใช้ที่มีสิทธิ์มากกว่า 1 สาขาเลือกได้ตอน login
/// หรือสลับได้ทีหลังที่หน้าบัญชี
class Branch {
  const Branch({
    required this.id,
    required this.name,
    this.code,
    this.address,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String? code;
  final String? address;
  final bool isActive;
}
