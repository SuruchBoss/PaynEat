// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/localization/order_display.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';

/// `displayTarget` เคยเป็น getter บน [Order] เอง ซึ่งลาก `package:get` เข้า domain
/// (ผิด `CODING_STANDARDS.md` §4.1) ตอนนี้ย้ายมาเป็น extension ใน `core/` แล้ว
/// เทสต์จึงย้ายตามมาจาก `test/domain/entities_test.dart` — และเทียบทั้งสองทาง ไม่ใช่ทางเดียว
/// เหมือนเดิม เพราะกิ่ง "ไม่มีโต๊ะ" คือกิ่งที่ออเดอร์กลับบ้าน/เดลิเวอรีใช้จริง
void main() {
  Order orderWith({String? tableName, String type = OrderType.dineIn}) => Order(
    id: 1,
    code: 'ORD-20260101-0001',
    type: type,
    status: OrderStatus.open,
    subtotal: 100,
    total: 117.7,
    tableName: tableName,
  );

  group('OrderDisplay.displayTarget', () {
    test('ทานที่ร้าน — ขึ้นชื่อโต๊ะ', () {
      expect(orderWith(tableName: 'A1').displayTarget, 'โต๊ะ A1');
    });

    test('ไม่มีโต๊ะ — ขึ้นประเภทออเดอร์แทน', () {
      expect(
        orderWith(type: OrderType.takeaway).displayTarget,
        OrderType.label(OrderType.takeaway),
      );
      expect(
        orderWith(type: OrderType.delivery).displayTarget,
        OrderType.label(OrderType.delivery),
      );
    });
  });
}
