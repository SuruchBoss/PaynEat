// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

@Timeout(Duration(minutes: 3))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/features/customer/domain/entities/customer.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/order/domain/entities/cart_line.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/usecases/order_usecases.dart';
import 'package:payneat_pos/features/payment/domain/entities/payment.dart';
import 'package:payneat_pos/features/shift/domain/entities/shift.dart';

import 'support/backend_process.dart';
import 'support/pos_device.dart';
import 'support/scenario.dart';

/// บิลที่ลูกค้าใช้แต้มจ่าย (T11 #101, docs/DECISIONS.md #77 D7, #100): ลิ้นชักและ Z-report นับเฉพาะเงินสดที่รับจริง
/// แต้มแยกเป็นบรรทัดของตัวเอง และคืนเงินแบ่งเป็นเงินกับแต้มตามสัดส่วนที่ลูกค้าจ่ายมา ตัวเลขที่แอปเห็นก่อนกดยืนยัน
/// ตรงกับที่คืนจริง — บิล 100.05 ใช้ 40 แต้ม (1 แต้ม = 1 บาท) + เงินสด 60.05
void main() {
  late BackendProcess backend;
  late PosDevice manager;
  final flow = Scenario();

  late Shift shift;
  late Customer customer;
  late Payment pointsPayment;
  late Order pointsOrder;
  late int pointsAfterPaying;

  setUpAll(() async {
    backend = await BackendProcess.start();
    manager = PosDevice(backend.apiBaseUrl);
  });

  tearDownAll(() async {
    // ignore: avoid_print
    if (flow.hasFailed) print('──── backend log ────\n${backend.log}');
    await backend.stop();
  });

  Future<int> pointsOf(Customer customer) async => expectOk(
    await manager.customers.getById(customer.id),
    'แต้มของลูกค้า',
  ).pointsBalance;

  flow.step(
    'เปิดกะ 2000 ลูกค้าสะสมแต้มจากบิลแรก แล้วจ่ายบิลที่สองด้วย 40 แต้ม + เงินสด 60.05',
    () async {
      await manager.signIn('manager', 'manager123');
      // 1 บาทได้ 1 แต้ม ลูกค้าจะได้แต้มพอแลกจากบิลแรกบิลเดียว
      expectOk(
        await manager.settings.update(pointsEarnRateBaht: 1),
        'ตั้งอัตราสะสมแต้ม',
      );
      final leftover = expectOk(await manager.shifts.getCurrent(), 'กะที่ค้าง');
      if (leftover != null) {
        expectOk(
          await manager.shifts.close(
            leftover.id,
            countedCash: leftover.openingCash,
          ),
          'ปิดกะที่ค้าง',
        );
      }
      shift = expectOk(await manager.shifts.open(2000), 'เปิดกะ');

      customer = expectOk(
        await manager.customers.create(
          name: 'คุณแต้มเยอะ',
          phone: '0811112222',
        ),
        'สร้างลูกค้า',
      );
      final menu = expectOk(
        await manager.menu.getMenuItems(availableOnly: true),
        'เมนู',
      );
      final crispyPork = menu.firstWhere(
        (MenuItem item) => item.name == 'ข้าวหมูกรอบ',
      );
      Future<Order> open() async => expectOk(
        await manager.orders.createOrder(
          type: 'takeaway',
          customerId: customer.id,
          guestCount: 1,
          items: cartToPayload([CartLine(menuItem: crispyPork, quantity: 1)]),
        ),
        'เปิดบิลข้าวหมูกรอบ',
      );

      final first = await open();
      expect(first.total, baht(100.05));
      expectOk(
        await manager.payments.pay(
          orderId: first.id,
          method: PaymentMethod.cash,
          amount: 100.05,
          received: 100.05,
        ),
        'จ่ายบิลแรกด้วยเงินสด',
      );
      expect(await pointsOf(customer), greaterThanOrEqualTo(40));

      pointsOrder = await open();
      final paid = expectOk(
        await manager.payments.pay(
          orderId: pointsOrder.id,
          method: PaymentMethod.cash,
          amount: 100.05,
          received: 60.05,
          pointsToRedeem: 40,
        ),
        'จ่ายบิลที่สองด้วยแต้ม + เงินสด',
      );
      pointsPayment = paid.result.payment;
      expect(pointsPayment.pointsRedeemed, 40);
      pointsAfterPaying = await pointsOf(customer);
    },
  );

  flow.step(
    'Z-report ของกะนับเงินสดจริง 160.10 และแยกบรรทัดแลกแต้ม 40',
    () async {
      final z = expectOk(
        await manager.reports.getZReportByShift(shift.id),
        'Z-report ของกะ',
      );
      final methods = {for (final row in z.paymentMethods) row.method: row};
      expect(methods[PaymentMethod.cash]?.amount, baht(160.1));
      expect(methods[PaymentMethod.cash]?.count, 2);
      expect(methods[PaymentMethod.points]?.amount, baht(40));
      expect(methods[PaymentMethod.points]?.count, 1);
      expect(z.netSales, baht(200.1));
    },
  );

  flow.step(
    'ดูตัวอย่างก่อนคืน แล้วคืนตามนั้น: 50 = เงิน 31 + 19 แต้ม ที่เหลือคืนแต้มครบ ปิดกะส่วนต่าง 0',
    () async {
      final preview = expectOk(
        await manager.payments.previewRefund(pointsPayment.id, 50),
        'ดูตัวอย่างคืน 50',
      );
      expect(preview.cashAmount, baht(31));
      expect(preview.pointsReturned, 19);
      expect(preview.pointsValue, baht(19));

      final first = expectOk(
        await manager.payments.refund(
          paymentId: pointsPayment.id,
          amount: 50,
          reason: 'ลูกค้าคืนอาหาร',
        ),
        'คืน 50',
      );
      expect(first.cashAmount, preview.cashAmount);
      expect(first.pointsReturned, preview.pointsReturned);
      final rest = expectOk(
        await manager.payments.refund(
          paymentId: pointsPayment.id,
          amount: 50.05,
          reason: 'ลูกค้าคืนอาหาร',
        ),
        'คืนที่เหลือ',
      );
      expect(rest.cashAmount, baht(29.05));
      expect(rest.pointsReturned, 21);
      expect(await pointsOf(customer), pointsAfterPaying + 40);

      final receipt = expectOk(
        await manager.payments.getReceipt(pointsOrder.id),
        'ใบเสร็จ',
      ).receipt;
      expect(
        receipt.refunds.map((r) => (r.cashAmount, r.pointsReturned)).toList(),
        [(31.0, 19), (29.05, 21)],
      );

      // 2000 + 100.05 + 60.05 − 60.05 ที่คืนเป็นเงินสด
      final closed = expectOk(
        await manager.shifts.close(shift.id, countedCash: 2100.05),
        'ปิดกะ',
      );
      expect(closed.expectedCash, baht(2100.05));
      expect(closed.variance, baht(0));
    },
  );
}
