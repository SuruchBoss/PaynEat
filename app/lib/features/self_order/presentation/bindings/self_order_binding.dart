// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:get/get.dart';

import '../../domain/usecases/add_self_order_items_usecase.dart';
import '../../domain/usecases/get_self_order_menu_usecase.dart';
import '../../domain/usecases/get_self_order_table_usecase.dart';
import '../controllers/self_order_controller.dart';

/// DI ของหน้าสั่งอาหารเองผ่าน QR (ดู docs/tickets/17-qr-self-order.md)
class SelfOrderBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      SelfOrderController(
        getTableUseCase: Get.find<GetSelfOrderTableUseCase>(),
        getMenuUseCase: Get.find<GetSelfOrderMenuUseCase>(),
        addItemsUseCase: Get.find<AddSelfOrderItemsUseCase>(),
      ),
    );
  }
}
