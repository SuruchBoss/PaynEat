// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

@Timeout(Duration(minutes: 3))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/order/domain/entities/cart_line.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/usecases/order_usecases.dart';

import 'support/backend_process.dart';
import 'support/pos_device.dart';
import 'support/scenario.dart';

/// รวมบิลที่รับเงินไว้แล้ว (T09 #96, docs/DECISIONS.md #98): แอปอ่านหน้าดูตัวอย่างรวมบิลจาก JSON ที่ backend ส่งจริง
/// แล้วรวมจริง ยอดจ่ายแล้วและส่วนลดของบิลต้นทางตามไปที่บิลปลายทาง และบิลต้นทางปิดโดยไม่มีเงินค้าง
void main() {
  late BackendProcess backend;
  late PosDevice cashier;
  final flow = Scenario();

  late Order source;
  late Order target;

  setUpAll(() async {
    backend = await BackendProcess.start();
    cashier = PosDevice(backend.apiBaseUrl);
  });

  tearDownAll(() async {
    // ignore: avoid_print
    if (flow.hasFailed) print('──── backend log ────\n${backend.log}');
    await backend.stop();
  });

  flow.step(
    'เปิดสองบิล รับเงินสด 50 กับส่วนลด 10 บาทบนบิลต้นทาง แล้วดูตัวอย่างรวมบิล',
    () async {
      await cashier.signIn('cashier', 'cashier123');
      final menu = expectOk(
        await cashier.menu.getMenuItems(availableOnly: true),
        'เมนู',
      );
      final dishes = menu
          .where((MenuItem m) => !m.soldByWeight && !m.requiresSelection)
          .where((m) => m.price >= 60)
          .toList();
      Future<Order> open(MenuItem dish) async => expectOk(
        await cashier.orders.createOrder(
          type: 'takeaway',
          guestCount: 1,
          items: cartToPayload([CartLine(menuItem: dish, quantity: 1)]),
        ),
        'เปิดบิล ${dish.name}',
      );
      source = await open(dishes[0]);
      target = await open(dishes[1]);
      source = expectOk(
        await cashier.orders.applyDiscount(source.id, 'amount', 10),
        'ส่วนลด 10 บาท',
      );
      expectOk(
        await cashier.payments.pay(
          orderId: source.id,
          method: 'cash',
          amount: 50,
          received: 50,
        ),
        'รับเงินสด 50',
      );

      final preview = expectOk(
        await cashier.orders.previewMerge(target.id, source.id),
        'ดูตัวอย่างรวมบิล',
      );
      expect(preview.source.code, source.code);
      expect(preview.source.paid, baht(50));
      expect(preview.source.discount, baht(10));
      expect(preview.target.code, target.code);
      expect(preview.target.paid, baht(0));
      expect(preview.discount, baht(10));
      expect(preview.paid, baht(50));
      expect(preview.remaining, baht(preview.total - 50));
      expect(preview.refundRequired, baht(0));
      expect(preview.canMerge, isTrue);
    },
  );

  flow.step(
    'รวมบิล → ปลายทางได้ยอดจ่ายแล้วและส่วนลด ต้นทางปิดโดยไม่มีเงินค้าง',
    () async {
      final merged = expectOk(
        await cashier.orders.mergeOrders(target.id, source.id),
        'รวมบิล',
      );
      expect(merged.discountAmount, baht(10));
      final money = expectOk(
        await cashier.payments.getSummary(target.id),
        'ยอดชำระของบิลปลายทาง',
      );
      expect(money.paid, baht(50));
      expect(money.remaining, baht(merged.total - 50));

      final closed = expectOk(
        await cashier.orders.getOrder(source.id),
        'บิลต้นทาง',
      );
      expect(closed.status, 'cancelled');
      expect(closed.total, baht(0));
      final leftover = expectOk(
        await cashier.payments.getSummary(source.id),
        'ยอดชำระของบิลต้นทาง',
      );
      expect(leftover.paid, baht(0));
    },
  );
}
