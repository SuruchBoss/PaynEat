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
}
