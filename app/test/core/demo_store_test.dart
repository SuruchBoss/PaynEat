import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/demo/demo_store.dart';

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
}
