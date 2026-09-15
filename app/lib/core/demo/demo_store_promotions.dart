part of 'demo_store.dart';

// ------------------------------------------------------------ promotions ------
extension DemoStorePromotions on DemoStore {
  List<Map<String, dynamic>> promotionList({bool activeOnly = false}) =>
      promotions
          .where((row) => !activeOnly || row['isActive'] == true)
          .toList(growable: false);

  /// เฉพาะที่เปิดใช้งาน — ให้ [PromotionEngine] เป็นคนกรองวัน/เวลา/ยอดขั้นต่ำเองอีกที
  List<Map<String, dynamic>> _activePromotionsForEngine() => promotions
      .where((row) => row['isActive'] == true)
      .toList(growable: false);

  Map<String, dynamic> promotion(int id) => promotions.firstWhere(
    (row) => row['id'] == id,
    orElse: () => throw ApiException(
      message: 'promotion_error_not_found'.tr,
      statusCode: 404,
    ),
  );

  Map<String, dynamic>? _findPromotionById(int id) {
    for (final row in promotions) {
      if (row['id'] == id) return row;
    }
    return null;
  }

  Map<String, dynamic>? _promotionByCode(String code) {
    for (final row in promotions) {
      if ((row['code'] as String?)?.toUpperCase() == code.toUpperCase()) {
        return row;
      }
    }
    return null;
  }

  Map<String, dynamic> savePromotion(Map<String, dynamic> body, {int? id}) {
    final rawCode = body['code'] as String?;
    final code = rawCode == null || rawCode.isEmpty
        ? null
        : rawCode.toUpperCase();
    if (code != null) {
      final existing = _promotionByCode(code);
      if (existing != null && existing['id'] != id) {
        throw ApiException(
          message: 'promotion_error_code_taken'.trParams({'code': code}),
          statusCode: 409,
        );
      }
    }

    if (id == null) {
      final promotion = {
        'id': _nextId(),
        'name': body['name'],
        'type': body['type'],
        'value': (body['value'] as num).toDouble(),
        'code': code,
        'conditions': body['conditions'] ?? const {},
        'isActive': body['isActive'] ?? true,
        'validFrom': body['validFrom'],
        'validTo': body['validTo'],
        'createdAt': _now(),
        'updatedAt': _now(),
      };
      promotions.add(promotion);
      return promotion;
    }

    final promotion = this.promotion(id);
    body.forEach((key, value) {
      if (key == 'code') {
        promotion['code'] = code;
      } else {
        promotion[key] = value;
      }
    });
    promotion['updatedAt'] = _now();
    return promotion;
  }

  void deletePromotion(int id) {
    promotion(id); // 404 ถ้าไม่พบ
    promotions.removeWhere((row) => row['id'] == id);
  }
}
