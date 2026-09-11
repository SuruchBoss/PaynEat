import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/features/order/domain/services/promotion_engine.dart';

/// เทสต์ตรงกับ backend/tests/promotion-engine.test.js (พอร์ตมาจาก
/// backend/src/modules/orders/promotion.engine.js) หน่วยเป็นบาท (double) แทนสตางค์ (integer)
/// เพราะ [PromotionEngine] ทำงานกับรูปร่าง JSON เดียวกับที่ [PromotionModel] ใช้อยู่แล้ว
void main() {
  Map<String, dynamic> basePromotion({
    int id = 1,
    String type = 'percent',
    double value = 10, // 10%
    String? code,
    Map<String, dynamic> conditions = const {},
    bool isActive = true,
    String? validFrom,
    String? validTo,
  }) => {
    'id': id,
    'name': 'ทดสอบ',
    'type': type,
    'value': value,
    'code': code,
    'conditions': conditions,
    'isActive': isActive,
    'validFrom': validFrom,
    'validTo': validTo,
  };

  final items = [
    {
      'menuItemId': 10,
      'categoryId': 1,
      'lineTotal': 100.0,
      'quantity': 1,
      'status': 'pending',
    },
    {
      'menuItemId': 20,
      'categoryId': 2,
      'lineTotal': 50.0,
      'quantity': 1,
      'status': 'pending',
    },
  ];

  group('PromotionEngine.evaluatePromotion', () {
    test('โปรโมชันเปอร์เซ็นต์ ไม่จำกัดเมนู ใช้กับ subtotal ทั้งบิล', () {
      final result = PromotionEngine.evaluatePromotion(
        basePromotion(),
        items: items,
      );
      expect(result?['discountAmount'], 15.0); // 10% ของ 150 บาท
    });

    test(
      'โปรโมชันจำนวนเงินคงที่ ถูกจำกัดไม่ให้เกิน subtotal ที่เข้าเงื่อนไข',
      () {
        final promotion = basePromotion(type: 'amount', value: 9999);
        final result = PromotionEngine.evaluatePromotion(
          promotion,
          items: items,
        );
        expect(result?['discountAmount'], 150.0); // ชนเพดาน subtotal ทั้งบิล
      },
    );

    test('โปรโมชัน BOGO ให้ของถูกกว่าฟรีเมื่อซื้อครบคู่', () {
      final bogoItems = [
        {
          'menuItemId': 10,
          'categoryId': 1,
          'lineTotal': 60.0,
          'quantity': 2,
          'status': 'pending',
        },
      ];
      final promotion = basePromotion(type: 'bogo', value: 0);
      final result = PromotionEngine.evaluatePromotion(
        promotion,
        items: bogoItems,
      );
      expect(
        result?['discountAmount'],
        30.0,
      ); // 1 ใน 2 ชิ้น (ราคาต่อชิ้น 30 บาท) ฟรี
    });

    test('BOGO ข้ามเมนูที่เข้าเงื่อนไข เอาชิ้นที่ถูกที่สุดฟรีก่อน', () {
      final bogoItems = [
        {
          'menuItemId': 10,
          'categoryId': 1,
          'lineTotal': 80.0,
          'quantity': 1,
          'status': 'pending',
        },
        {
          'menuItemId': 20,
          'categoryId': 1,
          'lineTotal': 30.0,
          'quantity': 1,
          'status': 'pending',
        },
      ];
      final promotion = basePromotion(type: 'bogo', value: 0);
      final result = PromotionEngine.evaluatePromotion(
        promotion,
        items: bogoItems,
      );
      expect(
        result?['discountAmount'],
        30.0,
      ); // ชิ้นละ 80/30 บาท → ฟรีตัวถูกกว่า (30 บาท)
    });

    test('ยอดบิลไม่ถึงขั้นต่ำ → ใช้ไม่ได้', () {
      final promotion = basePromotion(conditions: {'minSubtotal': 200.0});
      final result = PromotionEngine.evaluatePromotion(promotion, items: items);
      expect(result, isNull);
    });

    test(
      'จำกัดเฉพาะหมวดหมู่ — คิดส่วนลดจาก subtotal เฉพาะรายการที่เข้าเงื่อนไข',
      () {
        final promotion = basePromotion(
          conditions: {
            'categoryIds': [1],
          },
        );
        final result = PromotionEngine.evaluatePromotion(
          promotion,
          items: items,
        );
        expect(
          result?['discountAmount'],
          10.0,
        ); // 10% ของ 100 บาท (แค่รายการ categoryId=1)
      },
    );

    test(
      'จำกัดเฉพาะเมนู — ไม่มีรายการที่เข้าเงื่อนไขเลยในบิลนี้ → ใช้ไม่ได้',
      () {
        final promotion = basePromotion(
          conditions: {
            'menuItemIds': [999],
          },
        );
        final result = PromotionEngine.evaluatePromotion(
          promotion,
          items: items,
        );
        expect(result, isNull);
      },
    );

    test('นอกช่วงวันในสัปดาห์ที่กำหนด → ใช้ไม่ได้', () {
      final now = DateTime(2026, 9, 14, 12); // วันจันทร์
      final promotion = basePromotion(
        conditions: {
          'daysOfWeek': [0, 6],
        },
      );
      final result = PromotionEngine.evaluatePromotion(
        promotion,
        items: items,
        now: now,
      );
      expect(result, isNull);
    });

    test('นอกช่วงเวลาที่กำหนด (happy hour) → ใช้ไม่ได้', () {
      final now = DateTime(2026, 9, 14, 20);
      final promotion = basePromotion(
        conditions: {'startTime': '14:00', 'endTime': '17:00'},
      );
      final result = PromotionEngine.evaluatePromotion(
        promotion,
        items: items,
        now: now,
      );
      expect(result, isNull);
    });

    test('ในช่วงเวลาที่กำหนด → ใช้ได้', () {
      final now = DateTime(2026, 9, 14, 15);
      final promotion = basePromotion(
        conditions: {'startTime': '14:00', 'endTime': '17:00'},
      );
      final result = PromotionEngine.evaluatePromotion(
        promotion,
        items: items,
        now: now,
      );
      expect(result, isNotNull);
    });

    test('นอกช่วง validFrom/validTo ของแคมเปญ → ใช้ไม่ได้', () {
      final promotion = basePromotion(
        validFrom: '2026-01-01',
        validTo: '2026-01-31',
      );
      final result = PromotionEngine.evaluatePromotion(
        promotion,
        items: items,
        now: DateTime(2026, 9, 14, 12),
      );
      expect(result, isNull);
    });

    test('ปิดใช้งาน (isActive=false) → ใช้ไม่ได้แม้เข้าเงื่อนไขอื่นครบ', () {
      final promotion = basePromotion(isActive: false);
      final result = PromotionEngine.evaluatePromotion(promotion, items: items);
      expect(result, isNull);
    });
  });

  group('PromotionEngine.findBestAutoPromotion', () {
    test('เลือกตัวที่ให้ส่วนลดมากที่สุดในบรรดาที่ไม่ใช้โค้ด', () {
      final promotions = [
        basePromotion(id: 1, type: 'percent', value: 5), // 5% = 7.50
        basePromotion(id: 2, type: 'amount', value: 20), // 20 บาท
      ];
      final best = PromotionEngine.findBestAutoPromotion(
        promotions,
        items: items,
      );
      expect(best?['promotionId'], 2);
      expect(best?['discountAmount'], 20.0);
    });

    test('ข้ามโปรโมชันที่ต้องใช้โค้ด แม้ให้ส่วนลดมากกว่า', () {
      final promotions = [
        basePromotion(id: 1, type: 'percent', value: 5),
        basePromotion(id: 2, type: 'amount', value: 9999, code: 'BIGDEAL'),
      ];
      final best = PromotionEngine.findBestAutoPromotion(
        promotions,
        items: items,
      );
      expect(best?['promotionId'], 1);
    });

    test('คืน null ถ้าไม่มีโปรโมชันไหนเข้าเงื่อนไขเลย', () {
      final promotions = [basePromotion(isActive: false)];
      final best = PromotionEngine.findBestAutoPromotion(
        promotions,
        items: items,
      );
      expect(best, isNull);
    });
  });

  group('PromotionEngine.describeIneligibility', () {
    test('บอกเหตุผลเฉพาะเจาะจงเมื่อโค้ดใช้ไม่ได้', () {
      expect(
        PromotionEngine.describeIneligibility(
          basePromotion(isActive: false),
          items: items,
        ),
        'โค้ดนี้ถูกปิดใช้งานแล้ว',
      );
      expect(
        PromotionEngine.describeIneligibility(
          basePromotion(validTo: '2020-01-01'),
          items: items,
        ),
        'โค้ดนี้หมดอายุหรือยังไม่เริ่มใช้งาน',
      );
      expect(
        PromotionEngine.describeIneligibility(
          basePromotion(conditions: {'minSubtotal': 99999.0}),
          items: items,
        ),
        'ยอดบิลยังไม่ถึงขั้นต่ำสำหรับโค้ดนี้',
      );
      expect(
        PromotionEngine.describeIneligibility(
          basePromotion(
            conditions: {
              'menuItemIds': [999],
            },
          ),
          items: items,
        ),
        'บิลนี้ไม่มีเมนูที่ร่วมรายการกับโค้ดนี้',
      );
      expect(
        PromotionEngine.describeIneligibility(basePromotion(), items: items),
        isNull,
      );
    });
  });
}
