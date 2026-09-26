// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/demo/demo_data_sources.dart';
import 'package:payneat_pos/core/localization/app_translations.dart';
import 'package:payneat_pos/core/scanning/camera_barcode_scanner.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/order/presentation/widgets/barcode_scan_field.dart';
import 'package:payneat_pos/features/order/presentation/widgets/weight_entry_dialog.dart';
import 'package:payneat_pos/features/scale/domain/entities/scale_status.dart';
import 'package:payneat_pos/features/scale/domain/repositories/scale_repository.dart';
import 'package:payneat_pos/features/scale/domain/usecases/scale_usecases.dart';
import 'package:payneat_pos/features/scale/presentation/widgets/live_scale_panel.dart';

/// ตาชั่งต่อสาย + สแกนด้วยกล้อง (ดู docs/tickets/22-live-scale-camera-scan.md)

/// ตาชั่งปลอม: สถานะเริ่มต้นกำหนดได้ และดันค่าใหม่เข้า stream ได้เหมือน socket event
class _FakeScaleRepository implements ScaleRepository {
  _FakeScaleRepository(this.initial);

  final ScaleStatus initial;
  final StreamController<ScaleStatus> readings =
      StreamController<ScaleStatus>.broadcast();

  @override
  Future<Result<ScaleStatus>> status() async => Result.success(initial);

  @override
  Stream<ScaleStatus> watch() => readings.stream;
}

class _FakeCameraScanner implements CameraBarcodeScanner {
  _FakeCameraScanner({this.code, this.isSupported = true});

  final String? code;
  int scans = 0;

  @override
  final bool isSupported;

  @override
  Future<String?> scan() async {
    scans++;
    return code;
  }
}

ScaleStatus _connected(ScaleReading? reading) => ScaleStatus(
  enabled: true,
  driver: 'tcp',
  connected: true,
  reading: reading,
);

/// GetMaterialApp ในเทสต์ต้องได้คำแปลเหมือนแอปจริง ไม่งั้น `.tr` คืนคีย์ดิบ
Widget _app(Widget home) => GetMaterialApp(
  translations: AppTranslations(),
  locale: const Locale('th', 'TH'),
  home: home,
);

const _ribeye = MenuItem(
  id: 20,
  categoryId: 8,
  name: 'ริบอาย',
  price: 1200,
  soldByWeight: true,
);

void main() {
  tearDown(Get.reset);

  _FakeScaleRepository registerScale(ScaleStatus initial) {
    final repository = _FakeScaleRepository(initial);
    Get.put(GetScaleStatusUseCase(repository));
    Get.put(WatchScaleUseCase(repository));
    addTearDown(repository.readings.close);
    return repository;
  }

  // FilledButton.icon เป็นคลาสลูกของ FilledButton — หาด้วย key ตรง ๆ (byType เทียบคลาสแบบตรงตัว)
  FilledButton useButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(const ValueKey('live-scale-use')));

  Future<List<int>> pumpPanel(WidgetTester tester) async {
    final used = <int>[];
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: LiveScalePanel(
            onUse: used.add,
            pricePreview: (grams) => '฿${(grams * 1.2).toStringAsFixed(2)}',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return used;
  }

  group('LiveScalePanel', () {
    testWidgets('ร้านไม่ได้ต่อตาชั่ง = ไม่แสดงอะไรเลย', (tester) async {
      registerScale(ScaleStatus.off);
      await pumpPanel(tester);
      expect(find.byKey(const ValueKey('live-scale-panel')), findsNothing);
    });

    testWidgets('ไม่ได้ผูก DI (เช่นเทสต์อื่น) ก็ไม่พัง แค่ไม่แสดง', (
      tester,
    ) async {
      await pumpPanel(tester);
      expect(find.byKey(const ValueKey('live-scale-panel')), findsNothing);
    });

    testWidgets(
      'ใช้น้ำหนักได้เฉพาะตอนนิ่ง — ระหว่างแกว่ง/เกินพิกัด/หลุด กดไม่ได้',
      (tester) async {
        final scale = registerScale(_connected(null));
        final used = await pumpPanel(tester);
        expect(find.byKey(const ValueKey('live-scale-panel')), findsOneWidget);
        expect(find.text('รอน้ำหนักจากตาชั่ง…'), findsOneWidget);
        expect(useButton(tester).onPressed, isNull);

        scale.readings.add(
          _connected(const ScaleReading(grams: 470, stable: false)),
        );
        await tester.pumpAndSettle();
        expect(find.text('0.470 กก.'), findsOneWidget);
        expect(find.text('กำลังชั่ง… รอตัวเลขนิ่งก่อน'), findsOneWidget);
        expect(useButton(tester).onPressed, isNull);

        scale.readings.add(
          _connected(
            const ScaleReading(grams: 0, stable: false, overload: true),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('เกินพิกัดตาชั่ง'), findsOneWidget);
        expect(useButton(tester).onPressed, isNull);

        scale.readings.add(
          _connected(const ScaleReading(grams: 485, stable: true)),
        );
        await tester.pumpAndSettle();
        expect(find.text('0.485 กก.'), findsOneWidget);
        expect(find.text('นิ่งแล้ว = ฿582.00'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('live-scale-use')));
        expect(used, [485]);

        // สายหลุด: ตัวเลขเดิมต้องหาย ไม่ค้างให้กดใช้
        scale.readings.add(
          const ScaleStatus(enabled: true, driver: 'tcp', connected: false),
        );
        await tester.pumpAndSettle();
        expect(find.text('0.485 กก.'), findsNothing);
        expect(find.textContaining('ตาชั่งไม่ได้เชื่อมต่อ'), findsOneWidget);
        expect(useButton(tester).onPressed, isNull);
      },
    );

    testWidgets('ตาชั่งว่าง (0 กรัม) นิ่งแต่ใช้ไม่ได้', (tester) async {
      registerScale(_connected(const ScaleReading(grams: 0, stable: true)));
      await pumpPanel(tester);
      expect(find.text('วางสินค้าบนตาชั่ง'), findsOneWidget);
      expect(useButton(tester).onPressed, isNull);
    });
  });

  group('WeightEntryDialog + ตาชั่งสด', () {
    testWidgets(
      'กด "ใช้น้ำหนักนี้" = ได้น้ำหนักจากตาชั่งทันทีโดยไม่ต้องพิมพ์',
      (tester) async {
        final scale = registerScale(_connected(null));
        await tester.pumpWidget(_app(const Scaffold()));
        final result = WeightEntryDialog.show(_ribeye);
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('live-scale-panel')), findsOneWidget);
        // ต่อตาชั่งไว้ = ไม่ต้องพิมพ์ คีย์บอร์ดต้องไม่ค้างบังตัวเลข
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.focusNode!.hasFocus, isFalse);

        scale.readings.add(
          _connected(const ScaleReading(grams: 485, stable: true)),
        );
        await tester.pumpAndSettle();
        // ราคาคิดด้วยสูตรเดียวกับตะกร้า: 1,200 × 0.485 = 582.00
        expect(find.text('นิ่งแล้ว = ฿582.00'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('live-scale-use')));
        await tester.pumpAndSettle();
        expect(await result, 485);
      },
    );

    testWidgets('ไม่ได้ต่อตาชั่ง: กล่องเหมือนเดิม กรอกเองได้', (tester) async {
      registerScale(ScaleStatus.off);
      await tester.pumpWidget(_app(const Scaffold()));
      final result = WeightEntryDialog.show(_ribeye);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('live-scale-panel')), findsNothing);
      await tester.enterText(find.byType(TextField), '0.3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(await result, 300);
    });
  });

  group('BarcodeScanField + กล้อง', () {
    Future<List<String>> pumpField(WidgetTester tester) async {
      final scanned = <String>[];
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: BarcodeScanField(
              onScanned: (code) async => scanned.add(code),
            ),
          ),
        ),
      );
      return scanned;
    }

    testWidgets('กดปุ่มกล้อง → รหัสที่อ่านได้เข้าเส้นทางเดียวกับเครื่องสแกน', (
      tester,
    ) async {
      final camera = _FakeCameraScanner(code: ' 2000102004850 ');
      Get.put<CameraBarcodeScanner>(camera);
      final scanned = await pumpField(tester);

      await tester.tap(find.byKey(const ValueKey('order-scan-camera')));
      await tester.pumpAndSettle();
      expect(camera.scans, 1);
      expect(scanned, ['2000102004850']);
    });

    testWidgets('ปิดกล้องโดยไม่ได้รหัส = ไม่ทำอะไร', (tester) async {
      Get.put<CameraBarcodeScanner>(_FakeCameraScanner());
      final scanned = await pumpField(tester);
      await tester.tap(find.byKey(const ValueKey('order-scan-camera')));
      await tester.pumpAndSettle();
      expect(scanned, isEmpty);
    });

    testWidgets(
      'อุปกรณ์ที่ไม่มีกล้อง (เดสก์ท็อป) ไม่เห็นปุ่มกล้อง แต่เครื่องสแกนยังใช้ได้',
      (tester) async {
        Get.put<CameraBarcodeScanner>(_FakeCameraScanner(isSupported: false));
        final scanned = await pumpField(tester);
        expect(find.byKey(const ValueKey('order-scan-camera')), findsNothing);

        await tester.enterText(find.byType(TextField), '8850999320014');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(scanned, ['8850999320014']);
      },
    );
  });

  group('DemoScaleDataSource (ตาชั่งจำลองในโหมดสาธิต)', () {
    test('วนรอบ ว่าง → แกว่ง → นิ่งที่น้ำหนักเป้าหมาย → ยกออก', () async {
      final demo = DemoScaleDataSource(
        interval: const Duration(milliseconds: 1),
      );
      final frames = await demo.watch().take(40).toList();

      expect(
        frames.every((status) => status.enabled && status.isSimulator),
        isTrue,
      );
      final readings = frames.map((status) => status.reading!).toList();
      expect(readings.first.grams, 0);
      expect(
        readings.sublist(3, 6).every((reading) => !reading.stable),
        isTrue,
      );
      expect(readings[6].usable, isTrue);
      expect(readings[6].grams, DemoScaleDataSource.targets[0]);
      expect(readings[17].stable, isFalse);
      // รอบถัดไปใช้น้ำหนักเป้าหมายถัดไป
      expect(readings[26].grams, DemoScaleDataSource.targets[1]);
    });
  });
}
