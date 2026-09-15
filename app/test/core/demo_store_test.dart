import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/demo/demo_store.dart';
import 'package:payneat_pos/core/errors/exceptions.dart';

/// เทสต์ตรงต่อ DemoStore เอง (ไม่ผ่าน data source/repository) เพื่อยืนยันว่าเมธอด
/// ที่ถูกแยกออกไปหลายไฟล์ตามโดเมนด้วย part/part of (auth, menu, tables, orders,
/// payments, reports, seed history) ยังทำงานร่วมกันถูกต้องเหมือนตอนเป็นไฟล์เดียว —
/// โดยเฉพาะจุดที่โดเมนหนึ่งเรียกใช้ private helper ของอีกโดเมน เช่น orders เรียก
/// _findTable ของ tables และ _findUser ของ auth
void main() {
  late DemoStore store;

  setUp(() => store = DemoStore());

  group('DemoStore auth', () {
    test('login ด้วยบัญชีที่ถูกต้องได้ token และ user', () {
      final result = store.login('admin', 'admin123');
      expect(result['token'], isNotEmpty);
      expect((result['user'] as Map)['username'], 'admin');
    });

    test('login ผิดรหัสผ่านโยน ApiException 401', () {
      expect(
        () => store.login('admin', 'ผิดแน่นอน'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('ไม่ถูกต้อง'),
          ),
        ),
      );
    });

    test('profile คืนข้อมูลตรงกับ token ที่ login ได้มา', () {
      final login = store.login('admin', 'admin123');
      final profile = store.profile(login['token'] as String);
      expect(profile['username'], 'admin');
    });
  });

  group('DemoStore menu + tables', () {
    test('menuList และ tableList มีข้อมูลตัวอย่างพร้อมใช้ทันที', () {
      expect(store.menuList(), isNotEmpty);
      expect(store.tableList(), isNotEmpty);
    });

    test('deleteCategory ล้มเหลวถ้ายังมีเมนูอยู่ในหมวดนั้น', () {
      final menu = store.menuList().first;
      expect(
        () => store.deleteCategory(menu['categoryId'] as int),
        throwsException,
      );
    });
  });

  group('DemoStore orders — ทำงานข้ามโดเมน (tables/auth) ได้ถูกต้อง', () {
    test('createOrder ผูก tableName/tableZone จากโดเมน tables ให้ถูกต้อง', () {
      final table = store.tableList().firstWhere(
        (t) => t['status'] == 'available',
      );
      final item = store.menuList().first;

      final order = store.createOrder(
        type: 'dine_in',
        tableId: table['id'] as int,
        guestCount: 2,
        items: [
          {'menuItemId': item['id'], 'quantity': 1, 'optionIds': []},
        ],
      );

      expect(order['tableName'], table['name']);
      expect(order['tableZone'], table['zone']);
      // โต๊ะต้องถูกตั้งเป็นไม่ว่างทันทีที่เปิดออเดอร์ (แก้ state ใน tables ผ่าน orders)
      expect(
        store.tableList().firstWhere((t) => t['id'] == table['id'])['status'],
        'occupied',
      );
    });

    test('เปิดออเดอร์ซ้ำที่โต๊ะซึ่งมีออเดอร์เปิดอยู่แล้วต้องถูกปฏิเสธ', () {
      final table = store.tableList().firstWhere(
        (t) => t['status'] == 'available',
      );
      final item = store.menuList().first;
      final items = [
        {'menuItemId': item['id'], 'quantity': 1, 'optionIds': []},
      ];

      store.createOrder(
        type: 'dine_in',
        tableId: table['id'] as int,
        guestCount: 2,
        items: items,
      );

      expect(
        () => store.createOrder(
          type: 'dine_in',
          tableId: table['id'] as int,
          guestCount: 2,
          items: items,
        ),
        throwsException,
      );
    });

    test('ครัวเดินสถานะครบทุกจานแล้วออเดอร์เปลี่ยนเป็น served อัตโนมัติ', () {
      final table = store.tableList().firstWhere(
        (t) => t['status'] == 'available',
      );
      final item = store.menuList().first;

      final order = store.createOrder(
        type: 'dine_in',
        tableId: table['id'] as int,
        guestCount: 2,
        items: [
          {'menuItemId': item['id'], 'quantity': 1, 'optionIds': []},
        ],
      );
      store.sendToKitchen(order['id'] as int);

      final itemId =
          (store.findOrder(order['id'] as int)['items'] as List).first['id']
              as int;
      store.updateItemStatus(order['id'] as int, itemId, 'cooking');
      store.updateItemStatus(order['id'] as int, itemId, 'ready');
      final result = store.updateItemStatus(
        order['id'] as int,
        itemId,
        'served',
      );

      expect(result['status'], 'served');
    });
  });

  group(
    'DemoStore payments — ใช้ _findUser ของ auth และ _freeTable ของ tables',
    () {
      test('จ่ายเต็มจำนวนแล้วปิดออเดอร์และคืนโต๊ะให้ว่าง', () {
        final table = store.tableList().firstWhere(
          (t) => t['status'] == 'available',
        );
        final item = store.menuList().first;

        final order = store.createOrder(
          type: 'dine_in',
          tableId: table['id'] as int,
          guestCount: 2,
          items: [
            {'menuItemId': item['id'], 'quantity': 2, 'optionIds': []},
          ],
        );
        final total = (order['total'] as num).toDouble();

        final result = store.pay(
          orderId: order['id'] as int,
          method: 'cash',
          amount: total,
          received: total,
          cashierId: 6, // พี่แอน — ยืนยันว่า _findUser ข้ามไฟล์ยังทำงาน
        );

        expect(result['isFullyPaid'], isTrue);
        expect((result['payment'] as Map)['cashierName'], isNotNull);
        expect(store.findOrder(order['id'] as int)['status'], 'paid');
        expect(
          store.tableList().firstWhere((t) => t['id'] == table['id'])['status'],
          'available',
        );
      });

      test('จ่ายเกินยอดคงเหลือต้องถูกปฏิเสธ', () {
        final table = store.tableList().firstWhere(
          (t) => t['status'] == 'available',
        );
        final item = store.menuList().first;
        final order = store.createOrder(
          type: 'dine_in',
          tableId: table['id'] as int,
          guestCount: 1,
          items: [
            {'menuItemId': item['id'], 'quantity': 1, 'optionIds': []},
          ],
        );
        final total = (order['total'] as num).toDouble();

        expect(
          () => store.pay(
            orderId: order['id'] as int,
            method: 'cash',
            amount: total + 1000,
          ),
          throwsException,
        );
      });
    },
  );

  group('DemoStore promotions — auto apply / โค้ด / ลบ / eligible list', () {
    Map<String, dynamic> openOrder() {
      final table = store.tableList().firstWhere(
        (t) => t['status'] == 'available',
      );
      final item = store.menuList().first;
      return store.createOrder(
        type: 'dine_in',
        tableId: table['id'] as int,
        guestCount: 2,
        items: [
          {'menuItemId': item['id'], 'quantity': 2, 'optionIds': []},
        ],
      );
    }

    // โปรโมชันถูกประเมินใหม่ตอน _recalculate() เท่านั้น (ตอนแก้ไขออเดอร์) ไม่ใช่ตอนอ่านเฉย ๆ
    // เหมือนกับฝั่ง backend เทสต์นี้เลยต้อง "แตะ" ออเดอร์เบา ๆ เพื่อบังคับคำนวณใหม่
    Map<String, dynamic> touch(int orderId) =>
        store.applyDiscount(orderId, 'none', 0);

    test(
      'สร้างโปรโมชัน auto (ไม่ใช้โค้ด) แล้ว apply ให้ออเดอร์ที่เข้าเงื่อนไขทันที',
      () {
        final promotion = store.savePromotion({
          'name': 'ลด 10%',
          'type': 'percent',
          'value': 10.0,
          'conditions': const {},
          'isActive': true,
        });

        final order = openOrder();
        final subtotal = (order['subtotal'] as num).toDouble();

        expect(order['promotionId'], promotion['id']);
        expect(order['promotionDiscountAmount'], subtotal * 0.1);
      },
    );

    test('ลบโปรโมชัน auto ที่ยังเข้าเงื่อนไขอยู่ ระบบใส่กลับให้ทันที', () {
      final promotion = store.savePromotion({
        'name': 'ลด 10%',
        'type': 'percent',
        'value': 10.0,
        'conditions': const {},
        'isActive': true,
      });
      final order = openOrder();

      final removed = store.removePromotion(order['id'] as int);
      expect(removed['promotionId'], promotion['id']);
    });

    test('ปิดใช้งานโปรโมชัน auto แล้วออเดอร์ต้องไม่มีโปรโมชันอีกต่อไป', () {
      final promotion = store.savePromotion({
        'name': 'ลด 10%',
        'type': 'percent',
        'value': 10.0,
        'conditions': const {},
        'isActive': true,
      });
      final order = openOrder();

      store.savePromotion({'isActive': false}, id: promotion['id'] as int);
      final result = touch(order['id'] as int);

      expect(result['promotionId'], isNull);
      expect(result['promotionDiscountAmount'], 0.0);
    });

    test('สร้างโปรโมชันแบบใช้โค้ดซ้ำต้องถูกปฏิเสธ', () {
      store.savePromotion({
        'name': 'ลด 20 บาท',
        'type': 'amount',
        'value': 20.0,
        'code': 'save20',
        'conditions': const {},
        'isActive': true,
      });

      expect(
        () => store.savePromotion({
          'name': 'ลด 20 บาท (ซ้ำ)',
          'type': 'amount',
          'value': 20.0,
          'code': 'SAVE20',
          'conditions': const {},
          'isActive': true,
        }),
        throwsException,
      );
    });

    test('กรอกโค้ดที่ไม่มีอยู่จริงถูกปฏิเสธ', () {
      final order = openOrder();
      expect(
        () => store.redeemPromotionCode(order['id'] as int, 'NOTREAL'),
        throwsException,
      );
    });

    test(
      'กรอกโค้ดที่ถูกต้อง apply ทันที และยึดโค้ดไว้แม้ auto ให้ส่วนลดมากกว่า',
      () {
        final auto = store.savePromotion({
          'name': 'ลด 10% ทั้งบิล',
          'type': 'percent',
          'value': 10.0,
          'conditions': const {},
          'isActive': true,
        });
        store.savePromotion({
          'name': 'ลด 20 บาท',
          'type': 'amount',
          'value': 20.0,
          'code': 'save20',
          'conditions': const {},
          'isActive': true,
        });

        final order = openOrder();
        final redeemed = store.redeemPromotionCode(
          order['id'] as int,
          'save20',
        );
        expect(redeemed['promotionCode'], 'SAVE20');
        expect(redeemed['promotionDiscountAmount'], 20.0);

        // auto (10%) ให้ส่วนลดมากกว่า 20 บาทแน่นอนที่ subtotal นี้ แต่ต้องยึดโค้ดที่กรอกไว้เป็นหลัก
        final afterTouch = touch(order['id'] as int);
        expect(afterTouch['promotionId'], redeemed['promotionId']);
        expect(afterTouch['promotionCode'], 'SAVE20');
        expect(auto['code'], isNull);
      },
    );

    test('ลบโปรโมชัน (โค้ด) ออก → กลับไปใช้ auto ที่ยังเข้าเงื่อนไขแทน', () {
      final auto = store.savePromotion({
        'name': 'ลด 10% ทั้งบิล',
        'type': 'percent',
        'value': 10.0,
        'conditions': const {},
        'isActive': true,
      });
      store.savePromotion({
        'name': 'ลด 20 บาท',
        'type': 'amount',
        'value': 20.0,
        'code': 'save20',
        'conditions': const {},
        'isActive': true,
      });
      final order = openOrder();
      store.redeemPromotionCode(order['id'] as int, 'save20');

      final result = store.removePromotion(order['id'] as int);
      expect(result['promotionId'], auto['id']);
      expect(result['promotionCode'], isNull);
    });

    test(
      'eligiblePromotions คืนเฉพาะรายการที่เข้าเงื่อนไขหรือกำลังใช้งานอยู่',
      () {
        final promotion = store.savePromotion({
          'name': 'ลด 10%',
          'type': 'percent',
          'value': 10.0,
          'conditions': const {},
          'isActive': true,
        });
        final order = openOrder();

        final eligible = store.eligiblePromotions(order['id'] as int);
        final entry = eligible.firstWhere(
          (row) => row['promotionId'] == promotion['id'],
        );
        expect(entry['isEligibleNow'], isTrue);
        expect(entry['isCurrentlyApplied'], isTrue);
        expect(entry['requiresCode'], isFalse);
      },
    );

    test(
      'ลบโปรโมชันที่เคยใช้ในออเดอร์แล้วไม่กระทบออเดอร์เก่า (snapshot ไว้แล้ว)',
      () {
        final promotion = store.savePromotion({
          'name': 'ลด 10%',
          'type': 'percent',
          'value': 10.0,
          'conditions': const {},
          'isActive': true,
        });
        final order = openOrder();
        expect(order['promotionId'], promotion['id']);

        store.deletePromotion(promotion['id'] as int);

        final stillThere = store.findOrder(order['id'] as int);
        expect(stillThere['promotionName'], 'ลด 10%');
      },
    );
  });

  group('DemoStore reports — มีข้อมูลจาก seed history ตั้งแต่สร้างขึ้นมา', () {
    test(
      'dashboard และ salesSummary มีข้อมูลให้ดูทันทีไม่ต้องรอสร้างออเดอร์ใหม่',
      () {
        final dashboard = store.dashboard();
        expect(dashboard['today'], isNotNull);
        expect(
          (dashboard['live'] as Map)['totalTables'],
          store.tableList().length,
        );

        final summary = store.salesSummary();
        expect(summary['orderCount'], isA<int>());
      },
    );
  });

  group('DemoStore ingredients — ตัดสต๊อกอัตโนมัติเมื่อขาย (ticket 06)', () {
    test(
      'CRUD พื้นฐาน + isLowStock คำนวณจาก currentStock/lowStockThreshold',
      () {
        final ingredient = store.saveIngredient({
          'name': 'กุ้งทดสอบ',
          'unit': 'กรัม',
          'currentStock': 100.0,
          'lowStockThreshold': 20.0,
        });
        expect(ingredient['isLowStock'], false);

        final updated = store.saveIngredient({
          'name': 'กุ้งทดสอบ (แก้ไข)',
          'unit': 'กรัม',
          'lowStockThreshold': 150.0,
        }, id: ingredient['id'] as int);
        expect(updated['name'], 'กุ้งทดสอบ (แก้ไข)');
        // currentStock (100) <= lowStockThreshold ใหม่ (150) → ใกล้หมด
        expect(updated['isLowStock'], true);
      },
    );

    test('adjustIngredientStock ปรับสต๊อกได้ และปฏิเสธ delta = 0', () {
      final ingredient = store.saveIngredient({
        'name': 'ข้าวทดสอบ',
        'unit': 'กก.',
        'currentStock': 10.0,
        'lowStockThreshold': 2.0,
      });
      final increased = store.adjustIngredientStock(ingredient['id'] as int, 5);
      expect(increased['currentStock'], 15.0);

      final decreased = store.adjustIngredientStock(
        ingredient['id'] as int,
        -20,
      );
      expect(decreased['currentStock'], -5.0);
      expect(decreased['isLowStock'], true);

      expect(
        () => store.adjustIngredientStock(ingredient['id'] as int, 0),
        throwsException,
      );
    });

    test('ลบวัตถุดิบที่ผูกกับเมนูอยู่ไม่ได้ ต้องเลิกผูกก่อน', () {
      final ingredient = store.saveIngredient({
        'name': 'หมูทดสอบ-ลบ',
        'unit': 'กรัม',
        'currentStock': 100.0,
        'lowStockThreshold': 20.0,
      });
      final category = store.categories.first;
      final menuItem = store.saveMenuItem({
        'name': 'เมนูทดสอบ-ผูกวัตถุดิบ',
        'categoryId': category['id'],
        'price': 10.0,
        'ingredients': [
          {'ingredientId': ingredient['id'], 'qtyPerUnit': 10},
        ],
      });

      expect(
        () => store.deleteIngredient(ingredient['id'] as int),
        throwsException,
      );

      store.saveMenuItem({
        'categoryId': category['id'],
        'ingredients': <Map<String, dynamic>>[],
      }, id: menuItem['id'] as int);
      store.deleteIngredient(ingredient['id'] as int);
      expect(
        store.ingredients.any((row) => row['id'] == ingredient['id']),
        false,
      );
    });

    test('เลือกวัตถุดิบซ้ำกันในเมนูเดียวไม่ได้', () {
      final ingredient = store.saveIngredient({
        'name': 'ไข่ทดสอบ',
        'unit': 'ฟอง',
        'currentStock': 50.0,
        'lowStockThreshold': 10.0,
      });
      final category = store.categories.first;

      expect(
        () => store.saveMenuItem({
          'name': 'เมนูทดสอบ-ซ้ำ',
          'categoryId': category['id'],
          'price': 10.0,
          'ingredients': [
            {'ingredientId': ingredient['id'], 'qtyPerUnit': 1},
            {'ingredientId': ingredient['id'], 'qtyPerUnit': 2},
          ],
        }),
        throwsException,
      );
    });

    test('ผูกวัตถุดิบที่ไม่มีอยู่จริงไม่ได้', () {
      final category = store.categories.first;
      expect(
        () => store.saveMenuItem({
          'name': 'เมนูทดสอบ-ไม่มีวัตถุดิบ',
          'categoryId': category['id'],
          'price': 10.0,
          'ingredients': [
            {'ingredientId': 999999, 'qtyPerUnit': 1},
          ],
        }),
        throwsException,
      );
    });

    test(
      'flow: สั่ง → ส่งครัว → ตัดสต๊อก → หมด → ปิดขายอัตโนมัติ → ยกเลิก/ปรับ/ลบ → คืนสต๊อก → เปิดขายกลับ',
      () {
        final ingredient = store.saveIngredient({
          'name': 'วัตถุดิบทดสอบ-flow',
          'unit': 'ชิ้น',
          'currentStock': 3.0,
          'lowStockThreshold': 1.0,
        });
        final ingredientId = ingredient['id'] as int;
        final category = store.categories.first;
        final menuItem = store.saveMenuItem({
          'name': 'เมนูทดสอบ-flow',
          'categoryId': category['id'],
          'price': 50.0,
          'ingredients': [
            {'ingredientId': ingredientId, 'qtyPerUnit': 1},
          ],
        });
        final menuItemId = menuItem['id'] as int;
        final table = store.tableList().firstWhere(
          (t) => t['status'] == 'available',
        );

        // 1) สั่ง 2 ที่ — ยังไม่ตัดสต๊อกจนกว่าจะส่งครัว
        final order = store.createOrder(
          type: 'dine_in',
          tableId: table['id'] as int,
          guestCount: 2,
          items: [
            {'menuItemId': menuItemId, 'quantity': 2, 'optionIds': []},
          ],
        );
        expect(store.ingredient(ingredientId)['currentStock'], 3.0);

        // 2) ส่งครัว → ตัดสต๊อก 2 ชิ้น เหลือ 1 (ยังพอขายได้)
        store.sendToKitchen(order['id'] as int);
        expect(store.ingredient(ingredientId)['currentStock'], 1.0);
        expect(store.menuItem(menuItemId)['isAvailable'], true);

        // 3) ส่งครัวซ้ำไม่ตัดซ้ำ (idempotent)
        store.sendToKitchen(order['id'] as int);
        expect(store.ingredient(ingredientId)['currentStock'], 1.0);

        // 4) เพิ่มรายการเข้าออเดอร์ที่ส่งครัวไปแล้ว → ตัดทันที จนสต๊อกหมด
        store.addItems(order['id'] as int, [
          {'menuItemId': menuItemId, 'quantity': 1, 'optionIds': []},
        ]);
        expect(store.ingredient(ingredientId)['currentStock'], 0.0);
        expect(store.menuItem(menuItemId)['isAvailable'], false);
        expect(store.menuItem(menuItemId)['autoDisabledByStock'], true);

        // 5) สั่งเมนูที่ปิดขายอยู่ในออเดอร์ใหม่ต้องถูกปฏิเสธ
        final table2 = store.tableList().firstWhere(
          (t) => t['status'] == 'available' && t['id'] != table['id'],
        );
        expect(
          () => store.createOrder(
            type: 'dine_in',
            tableId: table2['id'] as int,
            guestCount: 1,
            items: [
              {'menuItemId': menuItemId, 'quantity': 1, 'optionIds': []},
            ],
          ),
          throwsException,
        );

        // 6) ยกเลิกรายการที่เพิ่งเพิ่ม (ยัง pending) → คืนสต๊อก → เปิดขายกลับอัตโนมัติ
        final justAddedItem =
            (store.findOrder(order['id'] as int)['items'] as List)
                .cast<Map<String, dynamic>>()
                .firstWhere((item) => item['quantity'] == 1);
        store.updateItemStatus(
          order['id'] as int,
          justAddedItem['id'] as int,
          'cancelled',
        );
        expect(store.ingredient(ingredientId)['currentStock'], 1.0);
        expect(store.menuItem(menuItemId)['isAvailable'], true);
        expect(store.menuItem(menuItemId)['autoDisabledByStock'], false);

        // 7) ปรับสต๊อกด้วยมือให้เป็น 0 ก็ปิดขายอัตโนมัติเหมือนกัน
        store.adjustIngredientStock(ingredientId, -1);
        expect(store.ingredient(ingredientId)['currentStock'], 0.0);
        expect(store.menuItem(menuItemId)['isAvailable'], false);

        // 8) เติมสต๊อกกลับก็เปิดขายอัตโนมัติ
        store.adjustIngredientStock(ingredientId, 5);
        expect(store.ingredient(ingredientId)['currentStock'], 5.0);
        expect(store.menuItem(menuItemId)['isAvailable'], true);

        // 9) แก้จำนวนรายการที่ตัดสต๊อกไปแล้ว (2 → 4) ต้องปรับตามส่วนต่างเท่านั้น
        final firstItem = (store.findOrder(order['id'] as int)['items'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((item) => item['status'] == 'pending');
        store.updateItem(
          order['id'] as int,
          firstItem['id'] as int,
          quantity: 4,
        );
        expect(store.ingredient(ingredientId)['currentStock'], 3.0);

        // 10) ลบรายการที่ตัดสต๊อกไปแล้ว (qty 4) → คืนสต๊อกเต็มจำนวน
        store.removeItem(order['id'] as int, firstItem['id'] as int);
        expect(store.ingredient(ingredientId)['currentStock'], 7.0);

        // 11) เพิ่มรายการใหม่แล้วยกเลิกทั้งบิล → คืนสต๊อกให้ทุกรายการที่ตัดไปแล้ว
        store.addItems(order['id'] as int, [
          {'menuItemId': menuItemId, 'quantity': 2, 'optionIds': []},
        ]);
        expect(store.ingredient(ingredientId)['currentStock'], 5.0);
        store.cancelOrder(order['id'] as int, 'ทดสอบยกเลิกทั้งบิล');
        expect(store.ingredient(ingredientId)['currentStock'], 7.0);
      },
    );
  });

  group('DemoStore tax invoices — ใบกำกับภาษี (ticket 07)', () {
    // จ่ายเงินเต็มจำนวนให้ออเดอร์ใหม่ 1 ใบ (mirror ของ payments group ด้านบน)
    // เพื่อให้ issueTaxInvoice ผ่านเงื่อนไข "จ่ายครบแล้วเท่านั้น"
    Map<String, dynamic> paidOrder() {
      final table = store.tableList().firstWhere(
        (t) => t['status'] == 'available',
      );
      final item = store.menuList().first;
      final order = store.createOrder(
        type: 'dine_in',
        tableId: table['id'] as int,
        guestCount: 2,
        items: [
          {'menuItemId': item['id'], 'quantity': 1, 'optionIds': []},
        ],
      );
      final total = (order['total'] as num).toDouble();
      store.pay(
        orderId: order['id'] as int,
        method: 'cash',
        amount: total,
        received: total,
        cashierId: 6,
      );
      return store.findOrder(order['id'] as int);
    }

    test(
      'ออกใบกำกับภาษีอย่างย่อสำเร็จ — เลขที่รันตรงรูปแบบ INV<ปี พ.ศ. 2 หลัก>-<เลขรัน 6 หลัก>',
      () {
        final order = paidOrder();
        final invoice = store.issueTaxInvoice(order['id'] as int, {
          'invoiceType': TaxInvoiceType.abbreviated,
        });

        final buddhistYear = DateTime.now().year + 543;
        final yy = buddhistYear.toString().substring(
          buddhistYear.toString().length - 2,
        );
        expect(invoice['runningNumber'], matches(RegExp('^INV$yy-\\d{6}\$')));
        expect(invoice['invoiceType'], TaxInvoiceType.abbreviated);
        expect(invoice['isVoid'], false);
      },
    );

    test('ใบกำกับภาษีเต็มรูปต้องระบุชื่อและที่อยู่ลูกค้า ไม่งั้นถูกปฏิเสธ', () {
      final order = paidOrder();
      expect(
        () => store.issueTaxInvoice(order['id'] as int, {
          'invoiceType': TaxInvoiceType.full,
        }),
        throwsException,
      );

      final invoice = store.issueTaxInvoice(order['id'] as int, {
        'invoiceType': TaxInvoiceType.full,
        'customerName': 'บริษัท ทดสอบ จำกัด',
        'customerAddress': '123 ถนนทดสอบ',
      });
      expect(invoice['customerName'], 'บริษัท ทดสอบ จำกัด');
      // เลขผู้เสียภาษีลูกค้าไม่บังคับแม้เต็มรูป (ดู docs/tickets/07-tax-invoice.md)
      expect(invoice['customerTaxId'], isNull);
    });

    test('ออกซ้ำให้ออเดอร์เดียวกันไม่ได้ถ้ายังไม่ยกเลิกใบเดิม', () {
      final order = paidOrder();
      store.issueTaxInvoice(order['id'] as int, {
        'invoiceType': TaxInvoiceType.abbreviated,
      });

      expect(
        () => store.issueTaxInvoice(order['id'] as int, {
          'invoiceType': TaxInvoiceType.abbreviated,
        }),
        throwsException,
      );
    });

    test('ออกใบกำกับภาษีให้ออเดอร์ที่ยังไม่จ่ายเงินไม่ได้', () {
      final table = store.tableList().firstWhere(
        (t) => t['status'] == 'available',
      );
      final item = store.menuList().first;
      final order = store.createOrder(
        type: 'dine_in',
        tableId: table['id'] as int,
        guestCount: 1,
        items: [
          {'menuItemId': item['id'], 'quantity': 1, 'optionIds': []},
        ],
      );

      expect(
        () => store.issueTaxInvoice(order['id'] as int, {
          'invoiceType': TaxInvoiceType.abbreviated,
        }),
        throwsException,
      );
    });

    test('เลขที่รันเรียงต่อเนื่องไม่ซ้ำข้ามหลายออเดอร์', () {
      final order1 = paidOrder();
      final order2 = paidOrder();
      final invoice1 = store.issueTaxInvoice(order1['id'] as int, {
        'invoiceType': TaxInvoiceType.abbreviated,
      });
      final invoice2 = store.issueTaxInvoice(order2['id'] as int, {
        'invoiceType': TaxInvoiceType.abbreviated,
      });

      expect(invoice1['runningNumber'], isNot(invoice2['runningNumber']));
      final seq1 = int.parse(
        (invoice1['runningNumber'] as String).split('-').last,
      );
      final seq2 = int.parse(
        (invoice2['runningNumber'] as String).split('-').last,
      );
      expect(seq2, seq1 + 1);
    });

    test('taxInvoiceForOrder โยน 404 ก่อนออก แล้วคืนใบล่าสุดหลังออกสำเร็จ', () {
      final order = paidOrder();
      expect(
        () => store.taxInvoiceForOrder(order['id'] as int),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );

      final issued = store.issueTaxInvoice(order['id'] as int, {
        'invoiceType': TaxInvoiceType.abbreviated,
      });
      expect(store.taxInvoiceForOrder(order['id'] as int)['id'], issued['id']);
    });

    test('ยกเลิกใบแล้วออกใหม่ได้ด้วยเลขที่รันใหม่ ไม่ใช้เลขเดิมซ้ำ', () {
      final order = paidOrder();
      final first = store.issueTaxInvoice(order['id'] as int, {
        'invoiceType': TaxInvoiceType.abbreviated,
      });

      final voided = store.voidTaxInvoice(
        order['id'] as int,
        'ออกผิดประเภท',
        voidedById: 2,
      );
      expect(voided['isVoid'], true);
      expect(voided['voidReason'], 'ออกผิดประเภท');
      expect(voided['voidedByName'], isNotNull);

      final second = store.issueTaxInvoice(order['id'] as int, {
        'invoiceType': TaxInvoiceType.abbreviated,
      });
      expect(second['runningNumber'], isNot(first['runningNumber']));
      expect(store.taxInvoiceForOrder(order['id'] as int)['id'], second['id']);
    });

    test('ยกเลิกใบกำกับภาษีที่ยังไม่เคยออกให้ออเดอร์นี้ไม่ได้ (404)', () {
      final order = paidOrder();
      expect(
        () => store.voidTaxInvoice(order['id'] as int, 'เหตุผลทดสอบ'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('ออกใบกำกับภาษีไม่ได้ถ้าร้านยังไม่ตั้งค่าเลขผู้เสียภาษี/ที่อยู่', () {
      final order = paidOrder();
      store.settings['storeTaxId'] = null;

      expect(
        () => store.issueTaxInvoice(order['id'] as int, {
          'invoiceType': TaxInvoiceType.abbreviated,
        }),
        throwsException,
      );
    });
  });

  group('DemoStore audit logs — บันทึกการกระทำที่เสี่ยง (ticket 08)', () {
    Map<String, dynamic> openOrder() {
      final table = store.tableList().firstWhere(
        (t) => t['status'] == 'available',
      );
      final item = store.menuList().first;
      return store.createOrder(
        type: 'dine_in',
        tableId: table['id'] as int,
        guestCount: 1,
        items: [
          {'menuItemId': item['id'], 'quantity': 1, 'optionIds': []},
        ],
      );
    }

    test('cancelOrder log เป็น order.cancel พร้อมเหตุผลและชื่อผู้ทำ', () {
      final order = openOrder();
      store.cancelOrder(order['id'] as int, 'ลูกค้ายกเลิก', actorId: 2);

      final logs = store.auditLogList(action: 'order.cancel');
      expect(logs, isNotEmpty);
      final log = logs.first;
      expect(log['entityType'], 'order');
      expect(log['entityId'], order['id']);
      expect(log['reason'], 'ลูกค้ายกเลิก');
      expect(log['actorName'], 'สมชาย (ผู้จัดการ)');
      expect(log['summary'], contains(order['code']));
    });

    test(
      'void รายการหลังครัวทำแล้ว log เป็น order_item.void แต่ยกเลิกตอน pending ไม่ log',
      () {
        final orderA = openOrder();
        final itemA = (orderA['items'] as List).first as Map<String, dynamic>;
        store.updateItemStatus(
          orderA['id'] as int,
          itemA['id'] as int,
          OrderItemStatus.cancelled,
          actorId: 3,
        );
        expect(
          store.auditLogList(
            action: 'order_item.void',
            entityId: itemA['id'] as int,
          ),
          isEmpty,
        );

        final orderB = openOrder();
        final itemB = (orderB['items'] as List).first as Map<String, dynamic>;
        store.updateItemStatus(
          orderB['id'] as int,
          itemB['id'] as int,
          OrderItemStatus.cooking,
        );
        store.updateItemStatus(
          orderB['id'] as int,
          itemB['id'] as int,
          OrderItemStatus.cancelled,
          actorId: 2,
        );

        final logs = store.auditLogList(
          action: 'order_item.void',
          entityId: itemB['id'] as int,
        );
        expect(logs, hasLength(1));
        expect(logs.first['entityType'], 'order_item');
        expect(logs.first['actorName'], 'สมชาย (ผู้จัดการ)');
      },
    );

    test(
      'applyDiscount log เป็น order.discount ทุกครั้งรวมถึงตอนยกเลิกส่วนลด',
      () {
        final order = openOrder();
        store.applyDiscount(
          order['id'] as int,
          DiscountType.percent,
          10,
          actorId: 6,
        );
        var logs = store.auditLogList(
          action: 'order.discount',
          entityId: order['id'] as int,
        );
        expect(logs, hasLength(1));
        expect(logs.first['metadata']['newType'], DiscountType.percent);

        store.applyDiscount(
          order['id'] as int,
          DiscountType.none,
          0,
          actorId: 6,
        );
        logs = store.auditLogList(
          action: 'order.discount',
          entityId: order['id'] as int,
        );
        expect(logs, hasLength(2));
      },
    );

    test(
      'updateStaff log แยก role_change/deactivate/password_reset แต่แก้ชื่อเฉยๆ ไม่ log',
      () {
        final created = store.createStaff(
          name: 'พนักงานทดสอบ audit log',
          username: 'audit_log_test_${DateTime.now().microsecondsSinceEpoch}',
          password: 'test1234',
          role: UserRole.waiter,
        );
        final userId = created['id'] as int;

        store.updateStaff(userId, {'role': UserRole.cashier}, actorId: 1);
        final roleLogs = store.auditLogList(
          action: 'user.role_change',
          entityId: userId,
        );
        expect(roleLogs, hasLength(1));
        expect(roleLogs.first['metadata']['previousRole'], UserRole.waiter);
        expect(roleLogs.first['metadata']['newRole'], UserRole.cashier);

        store.updateStaff(userId, {'isActive': false}, actorId: 1);
        expect(
          store.auditLogList(action: 'user.deactivate', entityId: userId),
          hasLength(1),
        );

        store.updateStaff(userId, {'password': 'newpassword'}, actorId: 1);
        expect(
          store.auditLogList(action: 'user.password_reset', entityId: userId),
          hasLength(1),
        );

        final before = store.auditLogList(entityId: userId).length;
        store.updateStaff(userId, {'name': 'ชื่อใหม่เฉยๆ'}, actorId: 1);
        expect(store.auditLogList(entityId: userId), hasLength(before));
      },
    );

    test('deleteStaff log เป็น user.delete แม้บัญชีจะถูกลบไปแล้ว', () {
      final created = store.createStaff(
        name: 'จะถูกลบ',
        username: 'audit_log_del_${DateTime.now().microsecondsSinceEpoch}',
        password: 'test1234',
        role: UserRole.waiter,
      );
      final userId = created['id'] as int;

      store.deleteStaff(userId, actorId: 1);

      final logs = store.auditLogList(action: 'user.delete', entityId: userId);
      expect(logs, hasLength(1));
      expect(logs.first['actorUserId'], 1);
      expect(logs.first['actorName'], 'ผู้ดูแลระบบ');
    });

    test(
      'updateSettings log เป็น settings.update เฉพาะตอนแก้ VAT/ค่าบริการ',
      () {
        final previousVat = store.settings['vatRate'] as double;
        store.updateSettings({'vatRate': previousVat + 0.01}, actorId: 1);
        expect(store.auditLogList(action: 'settings.update'), hasLength(1));

        store.updateSettings({'storeName': 'ร้านทดสอบ audit log'}, actorId: 1);
        expect(store.auditLogList(action: 'settings.update'), hasLength(1));
      },
    );

    test('refundPayment log เป็น payment.refund', () {
      final order = openOrder();
      final total = (order['total'] as num).toDouble();
      final payment = store.pay(
        orderId: order['id'] as int,
        method: 'cash',
        amount: total,
        received: total,
        cashierId: 6,
      );
      final paymentId = (payment['payment'] as Map)['id'] as int;

      final refund = store.refundPayment(
        paymentId: paymentId,
        amount: total,
        reason: 'ลูกค้าคืนอาหาร',
        refundedById: 2,
      );

      final logs = store.auditLogList(
        action: 'payment.refund',
        entityId: refund['id'] as int,
      );
      expect(logs, hasLength(1));
      expect(logs.first['entityType'], 'refund');
      expect(logs.first['reason'], 'ลูกค้าคืนอาหาร');
    });

    test('voidTaxInvoice log เป็น tax_invoice.void', () {
      final table = store.tableList().firstWhere(
        (t) => t['status'] == 'available',
      );
      final item = store.menuList().first;
      final order = store.createOrder(
        type: 'dine_in',
        tableId: table['id'] as int,
        guestCount: 1,
        items: [
          {'menuItemId': item['id'], 'quantity': 1, 'optionIds': []},
        ],
      );
      final total = (order['total'] as num).toDouble();
      store.pay(
        orderId: order['id'] as int,
        method: 'cash',
        amount: total,
        received: total,
        cashierId: 6,
      );
      final invoice = store.issueTaxInvoice(order['id'] as int, {
        'invoiceType': TaxInvoiceType.abbreviated,
      });

      store.voidTaxInvoice(order['id'] as int, 'ออกผิดประเภท', voidedById: 1);

      final logs = store.auditLogList(
        action: 'tax_invoice.void',
        entityId: invoice['id'] as int,
      );
      expect(logs, hasLength(1));
      expect(logs.first['reason'], 'ออกผิดประเภท');
    });
  });

  group('DemoStore customers/loyalty — ลูกค้า/แต้มสะสม (ticket 09)', () {
    Map<String, dynamic> openOrder({int? customerId}) {
      final table = store.tableList().firstWhere(
        (t) => t['status'] == 'available',
      );
      final item = store.menuList().first;
      return store.createOrder(
        type: 'dine_in',
        tableId: table['id'] as int,
        customerId: customerId,
        guestCount: 1,
        items: [
          {'menuItemId': item['id'], 'quantity': 2, 'optionIds': []},
        ],
      );
    }

    test('createCustomer สร้างลูกค้าใหม่ pointsBalance เริ่มต้นเป็น 0', () {
      final customer = store.createCustomer(
        name: 'คุณสมหญิง',
        phone: '0812345678',
      );

      expect(customer['pointsBalance'], 0);
      expect(store.customers, contains(customer));
    });

    test('createCustomer ด้วยเบอร์โทรซ้ำต้องถูกปฏิเสธ', () {
      store.createCustomer(name: 'คุณสมหญิง', phone: '0812345678');

      expect(
        () => store.createCustomer(name: 'คุณสมชาย', phone: '0812345678'),
        throwsException,
      );
    });

    test('customerSearch ค้นหาได้ทั้งจากชื่อและเบอร์โทร (partial match)', () {
      store.createCustomer(name: 'สมหญิง ใจดี', phone: '0899999999');
      store.createCustomer(name: 'John Smith', phone: '0888888888');

      expect(store.customerSearch(search: 'สมหญิง'), hasLength(1));
      expect(store.customerSearch(search: '9999'), hasLength(1));
      expect(store.customerSearch(search: 'ไม่มีจริง'), isEmpty);
    });

    test(
      'createOrder ผูก customerId แล้ว order มี customerName/customerPhone',
      () {
        final customer = store.createCustomer(
          name: 'คุณสมหญิง',
          phone: '0812345678',
        );

        final order = openOrder(customerId: customer['id'] as int);

        expect(order['customerId'], customer['id']);
        expect(order['customerName'], customer['name']);
        expect(order['customerPhone'], customer['phone']);
      },
    );

    test('createOrder ด้วย customerId ที่ไม่มีจริงต้องถูกปฏิเสธ', () {
      expect(() => openOrder(customerId: 999999), throwsException);
    });

    test(
      'จ่ายเงินครบเต็มจำนวนของออเดอร์ที่ผูกลูกค้า → ได้แต้มสะสมตามอัตราที่ตั้งค่า',
      () {
        final customer = store.createCustomer(
          name: 'คุณสมหญิง',
          phone: '0812345678',
        );
        final order = openOrder(customerId: customer['id'] as int);
        final total = (order['total'] as num).toDouble();
        final earnRate = (store.settings['pointsEarnRateBaht'] as num)
            .toDouble();
        final expectedPoints = (total / earnRate).floor();

        final result = store.pay(
          orderId: order['id'] as int,
          method: 'cash',
          amount: total,
          received: total,
        );

        expect(result['isFullyPaid'], isTrue);
        expect((result['order'] as Map)['pointsEarned'], expectedPoints);
        expect(
          store.findCustomer(customer['id'] as int)['pointsBalance'],
          expectedPoints,
        );
      },
    );

    test('ออเดอร์ที่ไม่ได้ผูกลูกค้า จ่ายครบแล้วไม่ได้แต้ม', () {
      final order = openOrder();
      final total = (order['total'] as num).toDouble();

      store.pay(
        orderId: order['id'] as int,
        method: 'cash',
        amount: total,
        received: total,
      );

      expect(store.findOrder(order['id'] as int)['pointsEarned'], 0);
    });

    test('แยกจ่ายหลายรอบ ลูกค้าได้แต้มแค่ครั้งเดียวตอนจ่ายครบ', () {
      final customer = store.createCustomer(
        name: 'คุณสมหญิง',
        phone: '0812345678',
      );
      final order = openOrder(customerId: customer['id'] as int);
      final total = (order['total'] as num).toDouble();
      final half = total / 2;

      final firstResult = store.pay(
        orderId: order['id'] as int,
        method: 'cash',
        amount: half,
        received: half,
      );
      expect(firstResult['isFullyPaid'], isFalse);
      expect(store.findCustomer(customer['id'] as int)['pointsBalance'], 0);

      final remaining = total - half;
      final secondResult = store.pay(
        orderId: order['id'] as int,
        method: 'cash',
        amount: remaining,
        received: remaining,
      );
      expect(secondResult['isFullyPaid'], isTrue);

      final earnRate = (store.settings['pointsEarnRateBaht'] as num).toDouble();
      final expectedPoints = (total / earnRate).floor();
      expect(
        store.findCustomer(customer['id'] as int)['pointsBalance'],
        expectedPoints,
      );
    });

    test(
      'ใช้แต้มสะสมแลกส่วนลด → ลดยอดที่ต้องเก็บจริง แต่ไม่กระทบยอดที่นับเข้าออเดอร์',
      () {
        final customer = store.createCustomer(
          name: 'คุณสมหญิง',
          phone: '0812345678',
        );
        store.adjustCustomerPoints(customer['id'] as int, 50);
        final order = openOrder(customerId: customer['id'] as int);
        final total = (order['total'] as num).toDouble();
        final redeemRate = (store.settings['pointsRedeemValueBaht'] as num)
            .toDouble();
        const pointsToRedeem = 10;
        final redeemedValue = pointsToRedeem * redeemRate;

        final result = store.pay(
          orderId: order['id'] as int,
          method: 'cash',
          amount: total,
          received: total - redeemedValue,
          pointsToRedeem: pointsToRedeem,
        );

        final payment = result['payment'] as Map<String, dynamic>;
        // ยอดที่นับเข้าบัญชีจ่ายของออเดอร์ (amount) ต้องไม่ลดลงจากการใช้แต้ม —
        // ลดแค่ยอดที่เก็บเงินจริง (received) เท่านั้น (ดู docs/DECISIONS.md)
        expect(payment['amount'], total);
        expect(payment['pointsRedeemed'], pointsToRedeem);
        expect(payment['pointsRedeemedValue'], redeemedValue);
        expect(payment['received'], total - redeemedValue);
        expect(result['isFullyPaid'], isTrue);

        final earnRate = (store.settings['pointsEarnRateBaht'] as num)
            .toDouble();
        final earnedThisOrder = (total / earnRate).floor();
        expect(
          store.findCustomer(customer['id'] as int)['pointsBalance'],
          50 - pointsToRedeem + earnedThisOrder,
        );
      },
    );

    test('ใช้แต้มเกินยอดคงเหลือของลูกค้าต้องถูกปฏิเสธ', () {
      final customer = store.createCustomer(
        name: 'คุณสมหญิง',
        phone: '0812345678',
      );
      final order = openOrder(customerId: customer['id'] as int);
      final total = (order['total'] as num).toDouble();

      expect(
        () => store.pay(
          orderId: order['id'] as int,
          method: 'cash',
          amount: total,
          pointsToRedeem: 1,
        ),
        throwsException,
      );
    });

    test('ใช้แต้มโดยออเดอร์ไม่ได้ผูกลูกค้าต้องถูกปฏิเสธ', () {
      final order = openOrder();
      final total = (order['total'] as num).toDouble();

      expect(
        () => store.pay(
          orderId: order['id'] as int,
          method: 'cash',
          amount: total,
          pointsToRedeem: 1,
        ),
        throwsException,
      );
    });

    test('ใช้แต้มที่มีมูลค่าเกินยอดที่ต้องชำระรอบนี้ต้องถูกปฏิเสธ', () {
      final customer = store.createCustomer(
        name: 'คุณสมหญิง',
        phone: '0812345678',
      );
      store.adjustCustomerPoints(customer['id'] as int, 1000);
      final order = openOrder(customerId: customer['id'] as int);
      final total = (order['total'] as num).toDouble();
      final redeemRate = (store.settings['pointsRedeemValueBaht'] as num)
          .toDouble();
      // แต้มพอ (1000) แต่มูลค่าเกินยอดที่จ่ายจริงรอบนี้ (จ่ายแค่บางส่วน)
      final partialAmount = total / 4;
      final tooManyPoints = (partialAmount / redeemRate).ceil() + 10;

      expect(
        () => store.pay(
          orderId: order['id'] as int,
          method: 'cash',
          amount: partialAmount,
          pointsToRedeem: tooManyPoints,
        ),
        throwsException,
      );
    });
  });

  group('DemoStore takeaway/delivery — เลขคิวรับอาหาร (ticket 10)', () {
    Map<String, dynamic> openOrder({required String type, int? tableId}) {
      final item = store.menuList().first;
      return store.createOrder(
        type: type,
        tableId: tableId,
        guestCount: 1,
        items: [
          {'menuItemId': item['id'], 'quantity': 1, 'optionIds': []},
        ],
      );
    }

    test('ออเดอร์ทานที่ร้านไม่มีเลขคิว', () {
      final table = store.tableList().firstWhere(
        (t) => t['status'] == 'available',
      );
      final order = openOrder(
        type: OrderType.dineIn,
        tableId: table['id'] as int,
      );

      expect(order['queueNumber'], isNull);
    });

    test('ออเดอร์เดลิเวอรีไม่มีเลขคิว (ไรเดอร์อ้างอิงจาก code แทน)', () {
      final order = openOrder(type: OrderType.delivery);

      expect(order['tableId'], isNull);
      expect(order['queueNumber'], isNull);
    });

    test('ออเดอร์กลับบ้านหลายใบติดกัน ได้เลขคิวรันต่อเนื่องเริ่มที่ 1', () {
      final first = openOrder(type: OrderType.takeaway);
      final second = openOrder(type: OrderType.takeaway);
      final third = openOrder(type: OrderType.takeaway);

      expect(first['queueNumber'], 1);
      expect(second['queueNumber'], 2);
      expect(third['queueNumber'], 3);
    });

    test('เลขคิวนับแยกจากออเดอร์ dine_in/delivery ที่แทรกอยู่ระหว่างกัน', () {
      final table = store.tableList().firstWhere(
        (t) => t['status'] == 'available',
      );
      final firstTakeaway = openOrder(type: OrderType.takeaway);
      openOrder(type: OrderType.dineIn, tableId: table['id'] as int);
      openOrder(type: OrderType.delivery);
      final secondTakeaway = openOrder(type: OrderType.takeaway);

      expect(firstTakeaway['queueNumber'], 1);
      expect(secondTakeaway['queueNumber'], 2);
    });
  });
}
