// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

@Timeout(Duration(minutes: 3))
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/backend_process.dart';
import 'support/pos_device.dart';
import 'support/scenario.dart';

/// เขตเวลาของร้าน (T03 #94, docs/DECISIONS.md #101): แอปอ่านและตั้งเขตเวลาผ่าน backend จริง ค่าเริ่มต้น Asia/Bangkok
/// ชื่อที่ backend เก็บเป็นตัวพิมพ์มาตรฐาน และชื่อที่ไม่ใช่เขตเวลา IANA ได้ข้อความบอกเหตุผล ค่าเดิมไม่เปลี่ยน
void main() {
  late BackendProcess backend;
  late PosDevice manager;
  final flow = Scenario();

  setUpAll(() async {
    backend = await BackendProcess.start();
    manager = PosDevice(backend.apiBaseUrl);
  });

  tearDownAll(() async {
    // ignore: avoid_print
    if (flow.hasFailed) print('──── backend log ────\n${backend.log}');
    await backend.stop();
  });

  flow.step(
    'ค่าเริ่มต้น Asia/Bangkok แล้วตั้งเป็น asia/seoul ได้ Asia/Seoul',
    () async {
      await manager.signIn('manager', 'manager123');
      final current = expectOk(await manager.settings.get(), 'อ่านตั้งค่า');
      expect(current.timeZone, 'Asia/Bangkok');

      final saved = expectOk(
        await manager.settings.update(timeZone: 'asia/seoul'),
        'ตั้งเขตเวลา',
      );
      expect(saved.timeZone, 'Asia/Seoul');
    },
  );

  flow.step(
    'ชื่อที่ไม่ใช่เขตเวลา IANA ถูกปฏิเสธพร้อมเหตุผล และค่าเดิมยังอยู่',
    () async {
      final refused = await manager.settings.update(timeZone: 'Mars/Olympus');
      refused.fold(
        onSuccess: (_) => fail('ต้องถูกปฏิเสธ'),
        onFailure: (failure) =>
            expect(failure.message, contains('Mars/Olympus')),
      );
      final current = expectOk(await manager.settings.get(), 'อ่านตั้งค่า');
      expect(current.timeZone, 'Asia/Seoul');
    },
  );
}
