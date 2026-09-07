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
