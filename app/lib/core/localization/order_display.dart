// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:get/get.dart';

import '../constants/app_constants.dart';
import '../../features/order/domain/entities/order.dart';

/// ข้อความที่ใช้แสดงหัวออเดอร์ เช่น "โต๊ะ A3" หรือ "กลับบ้าน"
///
/// เคยเป็น getter อยู่บน [Order] เอง ซึ่งทำให้ entity ใน domain ต้อง import `package:get`
/// เพื่อเรียก `trParams` — ผิดกฎ §4.1 ที่เขียนว่า domain ต้องเป็น pure Dart
/// (`docs/CODING_STANDARDS.md`) และไม่มีอะไรจับได้จนกระทั่งกฎถูกเอามาแขวนใน CI
///
/// อยู่ที่ `core/` ที่เดียวเพราะคนใช้กระจายอยู่สองฟีเจอร์กับตัวสร้างใบเสร็จ และเป็นที่เดียวกับ
/// [OrderType.label] ที่แปลข้อความแบบเดียวกันอยู่ก่อนแล้ว
extension OrderDisplay on Order {
  String get displayTarget => tableName != null
      ? 'order_table_prefix'.trParams({'table': tableName!})
      : OrderType.label(type);
}
