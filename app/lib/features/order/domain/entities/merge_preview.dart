// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/// ยอดของบิลหนึ่งฝั่งก่อนรวม (T09 #96, docs/DECISIONS.md #98)
class MergePreviewSide {
  const MergePreviewSide({
    required this.code,
    required this.total,
    required this.paid,
    required this.discount,
    required this.promotionDiscount,
    this.promotionName,
  });

  final String code;
  final double total;
  final double paid;

  /// ส่วนลดที่กรอกเอง (บาท)
  final double discount;
  final double promotionDiscount;
  final String? promotionName;
}

/// ผลของการรวมบิลต้นทางเข้าบิลปลายทาง ก่อนกดยืนยัน — ยอดที่จ่ายแล้วและส่วนลดของทั้งสองฝั่งย้ายตามไปที่ปลายทาง
/// และโปรโมชันประเมินใหม่บนบิลที่รวมแล้ว (DECISIONS #77 D3, #98)
class MergePreview {
  const MergePreview({
    required this.target,
    required this.source,
    required this.total,
    required this.paid,
    required this.remaining,
    required this.refundRequired,
    required this.discount,
    required this.promotionDiscount,
    required this.discountLost,
    this.promotionName,
  });

  final MergePreviewSide target;
  final MergePreviewSide source;
  final double total;
  final double paid;
  final double remaining;

  /// ยอดบิลที่รวมแล้วต่ำกว่าเงินที่รับไว้ ต้องคืนส่วนต่างก่อนจึงจะรวมได้ (กติกา T07)
  final double refundRequired;
  final double discount;
  final double promotionDiscount;
  final String? promotionName;

  /// ส่วนลดรวมของทั้งสองบิลที่จะหายไปหลังรวม (โปรโมชันใช้ได้ตัวเดียวต่อบิล หรือติดเพดานยอดอาหาร)
  final double discountLost;

  bool get canMerge => refundRequired <= 0;
}
