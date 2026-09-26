// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

part of 'demo_store.dart';

// ------------------------------------------------- order promotions -----
extension DemoStoreOrderPromotions on DemoStore {
  /// หาโปรโมชันที่ใช้กับออเดอร์นี้ — ถ้าผูกโค้ดไว้ (ยังเข้าเงื่อนไขอยู่) ใช้โค้ดนั้นก่อนเสมอ
  /// ไม่งั้นหาโปรโมชัน auto (ไม่ใช้โค้ด) ที่ให้ส่วนลดมากที่สุดในบรรดาที่เข้าเงื่อนไข
  Map<String, dynamic> _resolvePromotionForOrder(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) {
    final pinnedCode = order['promotionCode'] as String?;
    if (pinnedCode != null) {
      final promotionId = order['promotionId'] as int?;
      final promotion = promotionId == null
          ? null
          : _findPromotionById(promotionId);
      final result = promotion == null
          ? null
          : PromotionEngine.evaluatePromotion(promotion, items: items);
      if (result != null) {
        return {
          'promotionId': result['promotionId'],
          'name': result['name'],
          'code': pinnedCode,
          'discountAmount': result['discountAmount'],
        };
      }
      return {
        'promotionId': null,
        'name': null,
        'code': null,
        'discountAmount': 0.0,
      };
    }

    final best = PromotionEngine.findBestAutoPromotion(
      _activePromotionsForEngine(),
      items: items,
    );
    if (best != null) {
      return {
        'promotionId': best['promotionId'],
        'name': best['name'],
        'code': null,
        'discountAmount': best['discountAmount'],
      };
    }
    return {
      'promotionId': null,
      'name': null,
      'code': null,
      'discountAmount': 0.0,
    };
  }

  /// กรอกโค้ดส่วนลด — ถ้าเข้าเงื่อนไขจะผูกไว้กับออเดอร์และคำนวณใหม่ทันที
  Map<String, dynamic> redeemPromotionCode(int orderId, String code) {
    final order = findOrder(orderId);
    _assertMutable(order);

    final promotion = _promotionByCode(code);
    if (promotion == null) {
      throw ApiException(
        message: 'promotion_error_code_not_found'.tr,
        statusCode: 404,
      );
    }

    final items = (order['items'] as List).cast<Map<String, dynamic>>();
    final reason = PromotionEngine.describeIneligibility(
      promotion,
      items: items,
    );
    if (reason != null) {
      // `reason` เป็นคีย์คำแปล ไม่ใช่ข้อความ — domain แปลเองไม่ได้ (CODING_STANDARDS §4.1)
      throw ApiException(message: reason.tr, statusCode: 400);
    }

    order['promotionId'] = promotion['id'];
    order['promotionName'] = promotion['name'];
    order['promotionCode'] = promotion['code'] as String;
    return _recalculate(order);
  }

  /// เอาโปรโมชันที่ผูกด้วยโค้ดออก — ถ้ายังเข้าเงื่อนไขโปรโมชันแบบ auto อื่นอยู่ ระบบจะใส่ให้ใหม่เอง
  Map<String, dynamic> removePromotion(int orderId) {
    final order = findOrder(orderId);
    _assertMutable(order);

    order['promotionId'] = null;
    order['promotionName'] = null;
    order['promotionCode'] = null;
    order['promotionDiscountAmount'] = 0.0;
    return _recalculate(order);
  }

  /// โปรโมชันทั้งหมดที่เข้าเงื่อนไขกับบิลนี้ตอนนี้ — ให้ UI แสดง "โปรโมชันที่ใช้ได้ตอนนี้"
  List<Map<String, dynamic>> eligiblePromotions(int orderId) {
    final order = findOrder(orderId);
    final items = (order['items'] as List).cast<Map<String, dynamic>>();

    final result = <Map<String, dynamic>>[];
    for (final promotion in _activePromotionsForEngine()) {
      final evaluated = PromotionEngine.evaluatePromotion(
        promotion,
        items: items,
      );
      final isEligibleNow = evaluated != null;
      final isCurrentlyApplied = order['promotionId'] == promotion['id'];
      if (!isEligibleNow && !isCurrentlyApplied) continue;

      result.add({
        'promotionId': promotion['id'],
        'name': promotion['name'],
        'type': promotion['type'],
        'requiresCode': promotion['code'] != null,
        'isEligibleNow': isEligibleNow,
        'discountAmountIfApplied': evaluated == null
            ? 0.0
            : evaluated['discountAmount'],
        'isCurrentlyApplied': isCurrentlyApplied,
      });
    }
    return result;
  }
}
