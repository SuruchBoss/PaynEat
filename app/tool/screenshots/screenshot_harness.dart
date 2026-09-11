import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/app/app.dart';
import 'package:payneat_pos/app/routes/app_routes.dart';
import 'package:payneat_pos/core/demo/demo_store.dart';
import 'package:payneat_pos/core/services/session_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/core/utils/app_clock.dart';
import 'package:payneat_pos/features/auth/domain/usecases/login_usecase.dart';

/// เครื่องมือถ่ายภาพหน้าจอของแอปโดยไม่ต้องใช้เบราว์เซอร์หรืออุปกรณ์จริง
///
/// ใช้ตัว render ของ flutter_test วาด widget จริงออกมาเป็น PNG
/// (รันด้วย `flutter test --update-goldens tool/screenshots/capture_test.dart`)
///
/// ไม่ได้อยู่ในโฟลเดอร์ test/ เพราะเป็นเครื่องมือทำเอกสาร ไม่ใช่เทสต์ที่ต้องรันใน CI
class ScreenshotHarness {
  const ScreenshotHarness._();

  static const String fontDir = 'assets/fonts';

  /// ขนาดหน้าจอมาตรฐานที่ใช้ถ่ายภาพ
  static const Size phone = Size(390, 844); // iPhone 14
  static const Size tablet = Size(1194, 834); // iPad Pro 11" แนวนอน
  static const Size desktop = Size(1440, 900); // จอโน้ตบุ๊ก

  /// เวลาที่ตรึงไว้ตอนถ่ายภาพ — ตั้งใจให้เป็นช่วงเย็นที่ร้านกำลังยุ่ง
  /// กราฟยอดขายรายชั่วโมงและออเดอร์ในครัวจะได้มีข้อมูลให้ดูเต็ม ๆ
  ///
  /// จงใจใช้เวลา "ตามเครื่อง" ไม่ใช่ UTC เพราะ `Formatters.parse` แปลง UTC
  /// กลับเป็นเวลาเครื่องก่อนแสดงผลอยู่แล้ว พอตรึงเป็นเวลาเครื่อง ค่าที่วาด
  /// ออกมาจึงเท่ากันทุกเครื่อง ไม่ว่า time zone จะตั้งไว้เป็นอะไร
  static final DateTime capturedAt = DateTime(2026, 9, 11, 19, 42);

  /// ตรึงนาฬิกาก่อนสร้างข้อมูลสาธิต
  ///
  /// ถ้าไม่ตรึง ภาพที่ถ่ายซ้ำจะได้ไฟล์ไม่เหมือนเดิมทุกครั้ง เพราะเวลาบนการ์ด
  /// ออเดอร์ ("· 07:45") เดินตามนาฬิกาจริง กลายเป็น diff ปลอมใน git ที่แยก
  /// ไม่ออกว่าอันไหนคือการเปลี่ยนแปลงจริงของ UI
  ///
  /// ต้องเรียก "ก่อน" [seedScenario] เพราะข้อมูลสาธิตประทับเวลาตอนถูกสร้าง
  static void freezeClock() => AppClock.freeze(capturedAt);

  /// คืนนาฬิกาจริง — เรียกใน tearDownAll เสมอ
  static void unfreezeClock() => AppClock.unfreeze();

  /// โหลดฟอนต์จริงเข้าไปใน test binding
  ///
  /// ถ้าไม่โหลด flutter_test จะวาดตัวอักษรเป็นกล่องดำ (ฟอนต์ Ahem)
  ///
  /// ลงทะเบียนสองชื่อ:
  /// - `NotoSansThai` คือชื่อที่ธีมของแอปเรียกใช้จริง (ดู `AppTheme.fontFamily`)
  /// - `Roboto` เผื่อ widget ของ Material ที่สร้าง TextStyle เองโดยไม่ผ่านธีม
  ///   จะได้ไม่หล่นไปโดนฟอนต์ Ahem แล้วกลายเป็นกล่องสี่เหลี่ยมในภาพ
  static Future<void> loadFonts() async {
    Future<void> load(String family, List<String> paths) async {
      final loader = FontLoader(family);
      for (final path in paths) {
        final bytes = File(path).readAsBytesSync();
        loader.addFont(
          Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
        );
      }
      await loader.load();
    }

    const thaiFaces = [
      '$fontDir/NotoSansThai-400.ttf',
      '$fontDir/NotoSansThai-500.ttf',
      '$fontDir/NotoSansThai-700.ttf',
      '$fontDir/NotoSansThai-800.ttf',
    ];
    await load('NotoSansThai', thaiFaces);
    await load('Roboto', thaiFaces);

    const materialIcons =
        '/opt/fl/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(materialIcons).existsSync()) {
      await load('MaterialIcons', [materialIcons]);
    }
  }

  /// เตรียม storage แล้ววางแอปจริงลงบน tester
  ///
  /// ปล่อยให้ GetMaterialApp เรียก InitialBinding เอง จะได้เป็นเส้นทางเดียวกับตอนใช้งานจริง
  static Future<void> launchApp(WidgetTester tester, Size size) async {
    setSurface(tester, size);
    Get.reset();

    // ใช้ storage แบบหน่วยความจำ เพราะใน testWidgets เวลาเป็นแบบจำลอง
    // การ await timeout ของ GetStorage.init() จะค้างตลอด
    Get.put<StorageService>(StorageService.memory(), permanent: true);

    await tester.pumpWidget(const PaynEatApp());
    await settle(tester);
  }

  /// ล็อกอินแล้วเข้าหน้าหลัก
  static Future<void> loginAs(
    WidgetTester tester,
    String username,
    String password,
  ) async {
    // ต้องใช้ runAsync เพราะใน testWidgets เวลาเป็นแบบจำลอง
    // Future.delayed ของ data source สาธิตจะไม่เดินถ้าไม่มีการ pump
    final result = await tester.runAsync(
      () => Get.find<LoginUseCase>()(
        LoginParams(username: username, password: password),
      ),
    );
    final session = result?.dataOrNull;
    if (session == null) {
      throw StateError('ล็อกอินบัญชีสาธิต $username ไม่สำเร็จ');
    }
    Get.find<SessionService>().start(user: session.user, token: session.token);

    // ไม่ await การนำทางของ GetX เพราะ Future จะ complete ตอน "หน้าถูกปิด" ไม่ใช่ตอนเปิดเสร็จ
    unawaited(Get.offAllNamed<void>(AppRoutes.home));
    await settle(tester);
  }

  /// ตั้งขนาดหน้าจอจำลอง
  static void setSurface(
    WidgetTester tester,
    Size size, {
    double pixelRatio = 2.0,
  }) {
    tester.view.physicalSize = size * pixelRatio;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.reset);
  }

  /// สร้างข้อมูลตัวอย่างให้หน้าจอดูสมจริง (โต๊ะมีลูกค้า, ครัวมีงาน)
  static ({int openOrderId, int kitchenOrderId, int paidOrderId})
  seedScenario() {
    final store = DemoStore.instance;

    // ตัวเรนเดอร์ของ flutter_test ไม่รองรับฟอนต์อีโมจิ จึงถอดไอคอนหมวดหมู่ออก
    // ไม่ให้ขึ้นเป็นกล่องว่างในภาพ (บนอุปกรณ์จริงอีโมจิแสดงผลปกติ)
    for (final category in store.categories) {
      category['icon'] = null;
    }

    // สร้างยอดขายของวันนี้กระจายตามเวลาเปิดร้าน เพื่อให้กราฟรายชั่วโมงในภาพประกอบ
    // ดูเหมือนวันขายจริง ไม่ขึ้นกับเวลาที่รันเครื่องมือถ่ายภาพ
    // ต้องทำก่อนสร้างออเดอร์ตัวอย่างด้านล่าง เพราะขั้นตอนนี้ล้างบิลนอกเวลาเปิดร้านทิ้ง
    _seedTodaySalesCurve(store);

    // โต๊ะ A1 — ออเดอร์ที่เพิ่งส่งครัว (ใช้ถ่ายหน้ารายละเอียดและจอครัว)
    final kitchenOrder = store.createOrder(
      type: 'dine_in',
      tableId: 1,
      guestCount: 2,
      waiterId: 3,
      items: [
        {
          'menuItemId': 2,
          'quantity': 2,
          'optionIds': [1023, 1031],
          'note': 'ไม่ใส่ผัก',
        },
        {
          'menuItemId': 17,
          'quantity': 2,
          'optionIds': [1101],
        },
      ],
    );
    store.sendToKitchen(kitchenOrder['id'] as int);

    // โต๊ะ B2 — ครัวกำลังทำอยู่
    final cooking = store.createOrder(
      type: 'dine_in',
      tableId: 11,
      guestCount: 4,
      waiterId: 4,
      items: [
        {
          'menuItemId': 6,
          'quantity': 1,
          'optionIds': [1063],
        },
        {
          'menuItemId': 11,
          'quantity': 1,
          'optionIds': [1073],
        },
        {'menuItemId': 10, 'quantity': 1},
      ],
    );
    store.sendToKitchen(cooking['id'] as int);
    for (final item in (cooking['items'] as List).take(2)) {
      store.updateItemStatus(
        cooking['id'] as int,
        item['id'] as int,
        'cooking',
      );
    }

    // โต๊ะ C1 — เสิร์ฟครบแล้ว รอเก็บเงิน (ใช้ถ่ายหน้าชำระเงิน)
    final ready = store.createOrder(
      type: 'dine_in',
      tableId: 15,
      guestCount: 3,
      waiterId: 3,
      items: [
        {
          'menuItemId': 1,
          'quantity': 1,
          'optionIds': [1011],
        },
        {'menuItemId': 22, 'quantity': 2},
        {'menuItemId': 19, 'quantity': 3},
      ],
    );
    store.sendToKitchen(ready['id'] as int);
    for (final item in (ready['items'] as List)) {
      final id = item['id'] as int;
      store.updateItemStatus(ready['id'] as int, id, 'cooking');
      store.updateItemStatus(ready['id'] as int, id, 'ready');
      store.updateItemStatus(ready['id'] as int, id, 'served');
    }

    // ออเดอร์ที่ปิดบิลแล้ว (ใช้ถ่ายใบเสร็จ) — แยกจ่าย QR + เงินสด
    final paid = store.createOrder(
      type: 'dine_in',
      tableId: 6,
      guestCount: 2,
      waiterId: 3,
      items: [
        {
          'menuItemId': 2,
          'quantity': 2,
          'optionIds': [1023, 1031],
          'note': 'ไม่ใส่ผัก',
        },
        {
          'menuItemId': 17,
          'quantity': 2,
          'optionIds': [1101],
        },
      ],
    );
    final paidId = paid['id'] as int;
    store.sendToKitchen(paidId);
    for (final item in (paid['items'] as List)) {
      final id = item['id'] as int;
      store.updateItemStatus(paidId, id, 'cooking');
      store.updateItemStatus(paidId, id, 'ready');
      store.updateItemStatus(paidId, id, 'served');
    }
    store.applyDiscount(paidId, 'percent', 10);
    final total = (store.findOrder(paidId)['total'] as num).toDouble();
    store.pay(
      orderId: paidId,
      method: 'qr',
      amount: 100,
      reference: 'PROMPTPAY-4471',
      cashierId: 6,
    );
    final cashAmount = double.parse((total - 100).toStringAsFixed(2));
    store.pay(
      orderId: paidId,
      method: 'cash',
      amount: cashAmount,
      // ให้เงินเกินไว้เสมอ 20 บาท เพื่อให้มีเงินทอนในใบเสร็จตัวอย่าง
      // ไม่ล็อกเป็นค่าคงที่ เพราะยอดบิลจริงเปลี่ยนได้ตามราคาเมนู/ตัวเลือกที่ปรับ
      received: cashAmount + 20,
      cashierId: 6,
    );

    // ปรับเวลาสั่งของแต่ละตั๋วให้ต่างกัน เพื่อให้เห็นทั้งจานที่เพิ่งสั่งและจานที่รอนานเกินกำหนด
    void backdate(Map<String, dynamic> order, int index, int minutes) {
      final items = (order['items'] as List).cast<Map<String, dynamic>>();
      if (index < items.length) {
        items[index]['createdAt'] = AppClock.now()
            .toUtc()
            .subtract(Duration(minutes: minutes))
            .toIso8601String();
      }
    }

    backdate(kitchenOrder, 0, 18); // เกิน 15 นาที — จอครัวจะขึ้นเตือนสีแดง
    backdate(kitchenOrder, 1, 4);
    backdate(cooking, 0, 11);
    backdate(cooking, 1, 7);
    backdate(cooking, 2, 2);

    // ดันรายการหนึ่งไปถึงสถานะ "พร้อมเสิร์ฟ" ให้จอครัวมีตั๋วครบทั้งสามคอลัมน์
    final cookingItems = (cooking['items'] as List)
        .cast<Map<String, dynamic>>();
    store.updateItemStatus(
      cooking['id'] as int,
      cookingItems.first['id'] as int,
      'ready',
    );

    // ให้บิลที่ปิดแล้วอยู่ในช่วงมื้อเย็น ใบเสร็จในเอกสารจะได้ไม่ขึ้นเวลาแปลก ๆ
    // [capturedAt] เป็นช่วงมื้อเย็นอยู่แล้ว จึงใช้ค่านั้นตรง ๆ ได้เลย
    final paidStamp = capturedAt.toUtc().toIso8601String();
    final paidOrder = store.findOrder(paidId);
    paidOrder['createdAt'] = paidStamp;
    paidOrder['closedAt'] = paidStamp;
    for (final item
        in (paidOrder['items'] as List).cast<Map<String, dynamic>>()) {
      item['createdAt'] = paidStamp;
    }
    for (final payment in store.payments.where(
      (row) => row['orderId'] == paidId,
    )) {
      payment['createdAt'] = paidStamp;
    }

    return (
      openOrderId: ready['id'] as int,
      kitchenOrderId: kitchenOrder['id'] as int,
      paidOrderId: paidId,
    );
  }

  /// จำนวนบิลต่อชั่วโมงของวันขายทั่วไป — ช่วงเที่ยงและช่วงเย็นจะหนาแน่นกว่า
  static const Map<int, int> _billsPerHour = {
    11: 2,
    12: 5,
    13: 4,
    14: 2,
    15: 1,
    16: 2,
    17: 4,
    18: 6,
    19: 5,
    20: 3,
  };

  static void _seedTodaySalesCurve(DemoStore store) {
    final now = AppClock.now();

    // ตัดบิลของวันนี้ที่ตกนอกเวลาเปิดร้านออกก่อน (เกิดจากเวลาของเครื่องที่รันเครื่องมือ)
    // เพื่อให้กราฟในเอกสารเป็นวันขายวันเดียวที่อ่านง่าย
    final today = now.toIso8601String().substring(0, 10);
    bool outsideServiceHours(Map<String, dynamic> order) {
      final created = DateTime.tryParse(
        order['createdAt'] as String? ?? '',
      )?.toLocal();
      if (created == null) return false;
      if (created.toIso8601String().substring(0, 10) != today) return false;
      return created.hour < 11 || created.hour > 21;
    }

    final dropped = store.orders
        .where(outsideServiceHours)
        .map((o) => o['id'])
        .toSet();
    store.orders.removeWhere((order) => dropped.contains(order['id']));
    store.payments.removeWhere(
      (payment) => dropped.contains(payment['orderId']),
    );

    var sequence = 0;

    _billsPerHour.forEach((hour, count) {
      for (var i = 0; i < count; i++) {
        final at = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          (i * 11 + 3) % 60,
        );

        final order = store.createOrder(
          type: 'takeaway',
          guestCount: 1 + (sequence % 3),
          waiterId: 3,
          items: [
            {'menuItemId': 1 + (sequence % 24), 'quantity': 1 + (sequence % 2)},
            {'menuItemId': 1 + ((sequence + 7) % 24), 'quantity': 1},
          ],
        );
        final id = order['id'] as int;

        for (final item
            in (order['items'] as List).cast<Map<String, dynamic>>()) {
          store.updateItemStatus(id, item['id'] as int, 'cooking');
          store.updateItemStatus(id, item['id'] as int, 'ready');
          store.updateItemStatus(id, item['id'] as int, 'served');
        }

        final total = (store.findOrder(id)['total'] as num).toDouble();
        store.pay(
          orderId: id,
          method: const ['cash', 'qr', 'card', 'transfer'][sequence % 4],
          amount: total,
          received: total,
          cashierId: 6,
        );

        // ย้อนเวลาให้ตรงกับชั่วโมงที่ต้องการ ทั้งตัวออเดอร์และรายการอาหาร
        final stamp = at.toUtc().toIso8601String();
        final saved = store.findOrder(id);
        saved['createdAt'] = stamp;
        saved['closedAt'] = stamp;
        for (final item
            in (saved['items'] as List).cast<Map<String, dynamic>>()) {
          item['createdAt'] = stamp;
        }
        for (final payment in store.payments.where(
          (row) => row['orderId'] == id,
        )) {
          payment['createdAt'] = stamp;
        }

        sequence++;
      }
    });
  }

  /// รอให้แอนิเมชันและ Future ต่าง ๆ ทำงานจบ
  ///
  /// ไม่ใช้ pumpAndSettle เพราะบางหน้ามี timer วนซ้ำ (เช่นจอครัวที่นับเวลารอ)
  /// ซึ่งจะทำให้ pumpAndSettle รอไม่รู้จบ
  static Future<void> settle(WidgetTester tester, {int rounds = 12}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  /// บันทึกภาพหน้าจอ
  static Future<void> capture(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('images/$name.png'),
    );
  }
}
