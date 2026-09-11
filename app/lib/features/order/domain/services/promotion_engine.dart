import 'package:get/get.dart';

/// ตรรกะจับคู่โปรโมชันกับออเดอร์ — พอร์ตจาก backend/src/modules/orders/promotion.engine.js
/// ใช้เฉพาะฝั่ง Demo Mode (เห็น backend จริงทำหน้าที่นี้แทนตอนต่อ API จริง) เพื่อให้ demo
/// ทำงานครบฟีเจอร์โดยไม่ต้องมี backend
///
/// ไม่มีการจำกัดโปรโมชันซ้อนกันหลายใบ — ออเดอร์หนึ่งใช้ได้สูงสุด 1 โปรโมชัน (auto หรือใส่โค้ด)
/// รับ/คืนค่าเป็นหน่วยบาท (double) ตรงกับรูปร่าง JSON ที่ [PromotionModel] ใช้อยู่แล้ว
/// จึงไม่ต้องแปลงหน่วยเหมือนฝั่ง backend (satang/basis-point เป็นรายละเอียดเก็บข้อมูลเท่านั้น)
class PromotionEngine {
  const PromotionEngine._();

  static double _round(double value) => (value * 100).round() / 100;

  static double _sumActiveSubtotal(List<Map<String, dynamic>> items) => items
      .where((item) => item['status'] != 'cancelled')
      .fold<double>(
        0,
        (sum, item) => sum + (item['lineTotal'] as num).toDouble(),
      );

  static Map<String, dynamic> _conditionsOf(Map<String, dynamic> promotion) =>
      (promotion['conditions'] as Map?)?.cast<String, dynamic>() ?? const {};

  static bool _isWithinValidity(Map<String, dynamic> promotion, DateTime now) {
    final validFrom = promotion['validFrom'] as String?;
    final validTo = promotion['validTo'] as String?;
    if (validFrom != null &&
        now.isBefore(DateTime.parse('${validFrom}T00:00:00'))) {
      return false;
    }
    if (validTo != null && now.isAfter(DateTime.parse('${validTo}T23:59:59'))) {
      return false;
    }
    return true;
  }

  static bool _isWithinDayTime(Map<String, dynamic> conditions, DateTime now) {
    final daysOfWeek = (conditions['daysOfWeek'] as List? ?? const [])
        .map((value) => (value as num).toInt())
        .toList(growable: false);
    // Dart: จันทร์=1 ... อาทิตย์=7 · backend (JS Date#getDay): อาทิตย์=0 ... เสาร์=6
    final jsWeekday = now.weekday % 7;
    if (daysOfWeek.isNotEmpty && !daysOfWeek.contains(jsWeekday)) return false;

    final startTime = conditions['startTime'] as String?;
    final endTime = conditions['endTime'] as String?;
    if (startTime != null || endTime != null) {
      final hhmm =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      if (startTime != null && hhmm.compareTo(startTime) < 0) return false;
      if (endTime != null && hhmm.compareTo(endTime) > 0) return false;
    }
    return true;
  }

  /// รายการที่เข้าเงื่อนไขหมวดหมู่/เมนูของโปรโมชัน — ไม่ระบุเลย = ทั้งบิล
  static List<Map<String, dynamic>> _matchingItems(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> conditions,
  ) {
    final categoryIds = (conditions['categoryIds'] as List? ?? const [])
        .map((value) => (value as num).toInt())
        .toList(growable: false);
    final menuItemIds = (conditions['menuItemIds'] as List? ?? const [])
        .map((value) => (value as num).toInt())
        .toList(growable: false);
    if (categoryIds.isEmpty && menuItemIds.isEmpty) return items;

    return items
        .where(
          (item) =>
              (menuItemIds.isNotEmpty &&
                  menuItemIds.contains(item['menuItemId'])) ||
              (categoryIds.isNotEmpty &&
                  categoryIds.contains(item['categoryId'])),
        )
        .toList(growable: false);
  }

  /// ส่วนลด "ซื้อ 1 แถม 1" — กระจายเป็นราคาต่อชิ้น เรียงถูกไปแพง แล้วให้ครึ่งที่ถูกกว่าฟรี
  static double _calculateBogoDiscount(List<Map<String, dynamic>> items) {
    final unitPrices = <double>[];
    for (final item in items) {
      final lineTotal = (item['lineTotal'] as num).toDouble();
      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
      if (quantity <= 0) continue;
      final perUnit = _round(lineTotal / quantity);
      for (var i = 0; i < quantity; i++) {
        unitPrices.add(perUnit);
      }
    }
    unitPrices.sort();
    final freeCount = unitPrices.length ~/ 2;
    return _round(unitPrices.take(freeCount).fold<double>(0, (a, b) => a + b));
  }

  /// ประเมินโปรโมชันเดียวกับออเดอร์ — คืน `{promotionId, name, code, discountAmount}`
  /// ถ้าใช้ได้ หรือ `null` ถ้าไม่เข้าเงื่อนไขใดเงื่อนไขหนึ่ง
  static Map<String, dynamic>? evaluatePromotion(
    Map<String, dynamic> promotion, {
    required List<Map<String, dynamic>> items,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    if (promotion['isActive'] != true) return null;
    if (!_isWithinValidity(promotion, effectiveNow)) return null;

    final conditions = _conditionsOf(promotion);
    if (!_isWithinDayTime(conditions, effectiveNow)) return null;

    final minSubtotal = (conditions['minSubtotal'] as num?)?.toDouble() ?? 0;
    if (minSubtotal > 0 && _sumActiveSubtotal(items) < minSubtotal) return null;

    final active = items
        .where((item) => item['status'] != 'cancelled')
        .toList();
    final matched = _matchingItems(active, conditions);
    if (matched.isEmpty) return null;

    final eligibleSubtotal = _sumActiveSubtotal(matched);
    if (eligibleSubtotal <= 0) return null;

    final type = promotion['type'] as String;
    final value = (promotion['value'] as num).toDouble();
    double discountAmount;
    if (type == 'percent') {
      final percent = value.clamp(0, 100);
      discountAmount = _round(eligibleSubtotal * percent / 100);
    } else if (type == 'amount') {
      discountAmount = value < 0 ? 0 : value;
    } else {
      discountAmount = _calculateBogoDiscount(matched);
    }
    discountAmount = discountAmount > eligibleSubtotal
        ? eligibleSubtotal
        : discountAmount;
    if (discountAmount <= 0) return null;

    return {
      'promotionId': promotion['id'],
      'name': promotion['name'],
      'code': promotion['code'],
      'discountAmount': discountAmount,
    };
  }

  /// เลือกโปรโมชันที่ "ไม่ต้องใส่โค้ด" ที่ให้ส่วนลดมากที่สุดในบรรดาที่เข้าเงื่อนไข
  static Map<String, dynamic>? findBestAutoPromotion(
    List<Map<String, dynamic>> promotions, {
    required List<Map<String, dynamic>> items,
    DateTime? now,
  }) {
    Map<String, dynamic>? best;
    for (final promotion in promotions) {
      if (promotion['code'] != null) continue;
      final result = evaluatePromotion(promotion, items: items, now: now);
      if (result == null) continue;
      final bestAmount = (best?['discountAmount'] as double?) ?? -1;
      if ((result['discountAmount'] as double) > bestAmount) best = result;
    }
    return best;
  }

  /// ใช้ตอนลูกค้ากรอกโค้ดเอง — บอกเหตุผลที่ชัดเจนว่าทำไมใช้ไม่ได้
  /// คืน `null` ถ้าใช้ได้ปกติ หรือข้อความ (แปลแล้ว) อธิบายเหตุผลถ้าใช้ไม่ได้
  static String? describeIneligibility(
    Map<String, dynamic> promotion, {
    required List<Map<String, dynamic>> items,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    if (promotion['isActive'] != true) return 'promotion_error_inactive'.tr;
    if (!_isWithinValidity(promotion, effectiveNow)) {
      return 'promotion_error_expired'.tr;
    }

    final conditions = _conditionsOf(promotion);
    if (!_isWithinDayTime(conditions, effectiveNow)) {
      return 'promotion_error_not_in_time_window'.tr;
    }

    final minSubtotal = (conditions['minSubtotal'] as num?)?.toDouble() ?? 0;
    if (minSubtotal > 0 && _sumActiveSubtotal(items) < minSubtotal) {
      return 'promotion_error_min_subtotal_not_met'.tr;
    }

    final active = items
        .where((item) => item['status'] != 'cancelled')
        .toList();
    final matched = _matchingItems(active, conditions);
    if (matched.isEmpty) return 'promotion_error_no_matching_items'.tr;

    return null;
  }
}
