import '../../domain/entities/promotion.dart';

class PromotionConditionsModel extends PromotionConditions {
  const PromotionConditionsModel({
    super.daysOfWeek,
    super.startTime,
    super.endTime,
    super.categoryIds,
    super.menuItemIds,
    super.minSubtotal,
  });

  factory PromotionConditionsModel.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const {};
    return PromotionConditionsModel(
      daysOfWeek: (map['daysOfWeek'] as List? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(growable: false),
      startTime: map['startTime'] as String?,
      endTime: map['endTime'] as String?,
      categoryIds: (map['categoryIds'] as List? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(growable: false),
      menuItemIds: (map['menuItemIds'] as List? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(growable: false),
      minSubtotal: (map['minSubtotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PromotionModel extends Promotion {
  const PromotionModel({
    required super.id,
    required super.name,
    required super.type,
    required super.value,
    super.code,
    super.conditions,
    super.isActive,
    super.validFrom,
    super.validTo,
    super.createdAt,
    super.updatedAt,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) => PromotionModel(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    type: json['type'] as String? ?? 'percent',
    value: (json['value'] as num?)?.toDouble() ?? 0,
    code: json['code'] as String?,
    conditions: PromotionConditionsModel.fromJson(
      json['conditions'] as Map<String, dynamic>?,
    ),
    isActive: json['isActive'] as bool? ?? true,
    validFrom: json['validFrom'] as String?,
    validTo: json['validTo'] as String?,
    createdAt: json['createdAt'] as String?,
    updatedAt: json['updatedAt'] as String?,
  );
}

class EligiblePromotionModel extends EligiblePromotion {
  const EligiblePromotionModel({
    required super.promotionId,
    required super.name,
    required super.type,
    required super.requiresCode,
    required super.isEligibleNow,
    required super.discountAmountIfApplied,
    required super.isCurrentlyApplied,
  });

  factory EligiblePromotionModel.fromJson(Map<String, dynamic> json) =>
      EligiblePromotionModel(
        promotionId: (json['promotionId'] as num).toInt(),
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'percent',
        requiresCode: json['requiresCode'] as bool? ?? false,
        isEligibleNow: json['isEligibleNow'] as bool? ?? false,
        discountAmountIfApplied:
            (json['discountAmountIfApplied'] as num?)?.toDouble() ?? 0,
        isCurrentlyApplied: json['isCurrentlyApplied'] as bool? ?? false,
      );
}
