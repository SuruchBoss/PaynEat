// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/localization/app_translations.dart';
import 'package:payneat_pos/core/localization/locale_service.dart';
import 'package:payneat_pos/core/services/offline_order_queue_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/order/domain/repositories/order_repository.dart';
import 'package:payneat_pos/features/order/domain/usecases/order_usecases.dart';
import 'package:payneat_pos/features/order/presentation/controllers/cart_controller.dart';
import 'package:payneat_pos/features/order/presentation/widgets/cart_panel.dart';
import 'package:payneat_pos/features/settings/domain/entities/store_settings.dart';
import 'package:payneat_pos/features/settings/domain/repositories/settings_repository.dart';
import 'package:payneat_pos/features/settings/domain/usecases/settings_usecases.dart';

class _FakeOrderRepository implements OrderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<Result<StoreSettings>> get() async => const Result.success(
    StoreSettings(
      storeName: 'ร้านทดสอบ',
      currency: 'THB',
      vatRate: 0.07,
      serviceChargeRate: 0,
      vatIncluded: false,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// ตะกร้าต้องโชว์ชื่อเมนูตามภาษาที่เลือก เหมือนการ์ดเมนูที่เพิ่งแตะ
///
/// เจอตอนตรวจ UI หลัง ticket 18–20: การ์ดเมนูขึ้น "Beef Ribeye" / "소고기 꽃등심" แต่พอแตะแล้ว
/// บรรทัดในตะกร้ากลับเป็น "เนื้อวัวริบอาย" — cart_panel ใช้ `menuItem.name` (ไทยเสมอ)
/// มาตั้งแต่คอมมิตแรก ไม่ใช่ `displayName`
void main() {
  const ribeye = MenuItem(
    id: 26,
    categoryId: 8,
    name: 'เนื้อวัวริบอาย',
    nameEn: 'Beef Ribeye',
    nameKo: '소고기 꽃등심',
    price: 1200,
    soldByWeight: true,
  );
  const kimchi = MenuItem(
    id: 29,
    categoryId: 8,
    name: 'กิมจิ 500 กรัม',
    nameEn: 'Kimchi 500 g',
    nameKo: '김치 500g',
    price: 129,
  );

  tearDown(Get.reset);

  for (final (locale, expected) in [
    (LocaleService.english, ['Beef Ribeye', 'Kimchi 500 g']),
    (LocaleService.korean, ['소고기 꽃등심', '김치 500g']),
  ]) {
    testWidgets('[${locale.languageCode}] บรรทัดในตะกร้าใช้ชื่อตามภาษา', (
      tester,
    ) async {
      final orders = _FakeOrderRepository();
      final cart = Get.put(
        CartController(
          createOrder: CreateOrderUseCase(orders),
          addItems: AddOrderItemsUseCase(orders),
          sendToKitchen: SendToKitchenUseCase(orders),
          getSettings: GetSettingsUseCase(_FakeSettingsRepository()),
          offlineQueue: OfflineOrderQueueService(
            storage: StorageService.memory(),
            orderRepository: orders,
          ),
        ),
      );
      cart
        ..addWeighedItem(ribeye, 485)
        ..addItem(kimchi);

      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: locale,
          home: const Scaffold(body: CartPanel()),
        ),
      );
      await tester.pump();

      for (final name in expected) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('เนื้อวัวริบอาย'), findsNothing);
      expect(find.text('กิมจิ 500 กรัม'), findsNothing);
    });
  }
}
