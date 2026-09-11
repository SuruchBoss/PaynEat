import '../../../../core/constants/app_constants.dart';

/// เงื่อนไขของโปรโมชัน — ไม่ระบุอะไรเลย = ใช้ได้ทุกช่วงเวลา/ทุกเมนู/ไม่มีขั้นต่ำ
class PromotionConditions {
  const PromotionConditions({
    this.daysOfWeek = const [],
    this.startTime,
    this.endTime,
    this.categoryIds = const [],
    this.menuItemIds = const [],
    this.minSubtotal = 0,
  });

  /// วันในสัปดาห์ที่ร่วมรายการ (0 = อาทิตย์ ... 6 = เสาร์) ว่าง = ทุกวัน
  final List<int> daysOfWeek;

  /// ช่วงเวลาที่ร่วมรายการ รูปแบบ HH:mm — null = ไม่จำกัดเวลา
  final String? startTime;
  final String? endTime;

  /// หมวดหมู่/เมนูที่ร่วมรายการ — ว่างทั้งคู่ = ทั้งบิล
  final List<int> categoryIds;
  final List<int> menuItemIds;

  /// ยอดขั้นต่ำที่ต้องซื้อถึง (บาท) — 0 = ไม่มีขั้นต่ำ
  final double minSubtotal;

  bool get hasTimeWindow => startTime != null || endTime != null;
  bool get isWholeBill => categoryIds.isEmpty && menuItemIds.isEmpty;
}

/// โปรโมชัน/ส่วนลดแบบมีเงื่อนไข
class Promotion {
  const Promotion({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.code,
    this.conditions = const PromotionConditions(),
    this.isActive = true,
    this.validFrom,
    this.validTo,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;

  /// percent / amount / bogo — ดู [PromotionType]
  final String type;

  /// percent: 0-100 · amount: บาท · bogo: ไม่ใช้ค่านี้
  final double value;

  /// โค้ดส่วนลด — null = ระบบ apply ให้อัตโนมัติเมื่อเข้าเงื่อนไข ไม่ต้องกรอกโค้ด
  final String? code;
  final PromotionConditions conditions;
  final bool isActive;
  final String? validFrom;
  final String? validTo;
  final String? createdAt;
  final String? updatedAt;

  bool get requiresCode => code != null && code!.isNotEmpty;
  String get typeLabel => PromotionType.label(type);

  String get valueSummary => switch (type) {
    PromotionType.percent => '${value.toStringAsFixed(0)}%',
    PromotionType.amount => value.toStringAsFixed(0),
    _ => '',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Promotion && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// สรุปสถานะโปรโมชัน 1 รายการเทียบกับออเดอร์ปัจจุบัน — ใช้ตอนเลือกโปรโมชันให้ออเดอร์
class EligiblePromotion {
  const EligiblePromotion({
    required this.promotionId,
    required this.name,
    required this.type,
    required this.requiresCode,
    required this.isEligibleNow,
    required this.discountAmountIfApplied,
    required this.isCurrentlyApplied,
  });

  final int promotionId;
  final String name;
  final String type;
  final bool requiresCode;
  final bool isEligibleNow;
  final double discountAmountIfApplied;
  final bool isCurrentlyApplied;
}
