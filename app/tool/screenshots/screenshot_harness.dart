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
import 'package:payneat_pos/features/auth/domain/usecases/login_usecase.dart';

/// เครื่องมือถ่ายภาพหน้าจอของแอปโดยไม่ต้องใช้เบราว์เซอร์หรืออุปกรณ์จริง
///
/// ใช้ตัว render ของ flutter_test วาด widget จริงออกมาเป็น PNG
/// (รันด้วย `flutter test --update-goldens tool/screenshots/capture_test.dart`)
///
/// ไม่ได้อยู่ในโฟลเดอร์ test/ เพราะเป็นเครื่องมือทำเอกสาร ไม่ใช่เทสต์ที่ต้องรันใน CI
class ScreenshotHarness {
  const ScreenshotHarness._();

  static const String fontDir = 'tool/fonts';

  /// ขนาดหน้าจอมาตรฐานที่ใช้ถ่ายภาพ
  static const Size phone = Size(390, 844); // iPhone 14
  static const Size tablet = Size(1194, 834); // iPad Pro 11" แนวนอน
  static const Size desktop = Size(1440, 900); // จอโน้ตบุ๊ก

  /// โหลดฟอนต์จริงเข้าไปใน test binding
  ///
  /// ถ้าไม่โหลด flutter_test จะวาดตัวอักษรเป็นกล่องดำ (ฟอนต์ Ahem)
  /// ลงทะเบียน Noto Sans Thai เป็นชื่อ 'Roboto' เพื่อให้กลายเป็นฟอนต์เริ่มต้นของทั้งแอป
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

    await load('Roboto', [
      '$fontDir/NotoSansThai-400.ttf',
      '$fontDir/NotoSansThai-500.ttf',
      '$fontDir/NotoSansThai-700.ttf',
      '$fontDir/NotoSansThai-800.ttf',
    ]);

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
    store.pay(
      orderId: paidId,
      method: 'cash',
      amount: double.parse((total - 100).toStringAsFixed(2)),
      received: 200,
      cashierId: 6,
    );

    // ปรับเวลาสั่งของแต่ละตั๋วให้ต่างกัน เพื่อให้เห็นทั้งจานที่เพิ่งสั่งและจานที่รอนานเกินกำหนด
    void backdate(Map<String, dynamic> order, int index, int minutes) {
      final items = (order['items'] as List).cast<Map<String, dynamic>>();
      if (index < items.length) {
        items[index]['createdAt'] = DateTime.now()
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

    return (
      openOrderId: ready['id'] as int,
      kitchenOrderId: kitchenOrder['id'] as int,
      paidOrderId: paidId,
    );
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
