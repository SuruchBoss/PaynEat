import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_option.dart';
import 'package:payneat_pos/features/order/domain/entities/order_item_payload.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/repositories/order_repository.dart';
import 'package:payneat_pos/features/order/domain/usecases/order_usecases.dart';
import 'package:payneat_pos/features/order/presentation/controllers/cart_controller.dart';
import 'package:payneat_pos/features/settings/domain/entities/store_settings.dart';
import 'package:payneat_pos/features/settings/domain/repositories/settings_repository.dart';
import 'package:payneat_pos/features/settings/domain/usecases/settings_usecases.dart';

/// repository ปลอมสำหรับเทสต์ — เป็นไปได้เพราะ controller พึ่งพา abstract ไม่ใช่ HTTP จริง
/// นี่คือประโยชน์ที่จับต้องได้ของการแยกชั้นแบบ Clean Architecture
class _FakeOrderRepository implements OrderRepository {
  @override
  Future<Result<Order>> createOrder({
    required String type,
    int? tableId,
    required int guestCount,
    String? note,
    required List<OrderItemPayload> items,
  }) async => const Result.failure(UnexpectedFailureStub());

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
      serviceChargeRate: 0.1,
      vatIncluded: false,
    ),
  );

  @override
  Future<Result<StoreSettings>> update({
    String? storeName,
    double? vatRate,
    double? serviceChargeRate,
    bool? vatIncluded,
  }) async => get();
}

void main() {
  late CartController controller;

  const padkrapao = MenuItem(
    id: 10,
    categoryId: 1,
    name: 'ผัดกะเพรา',
    price: 75,
  );
  const somtum = MenuItem(id: 11, categoryId: 2, name: 'ส้มตำไทย', price: 80);
  const egg = MenuOption(id: 1, name: 'ไข่ดาว', priceDelta: 15);

  setUp(() {
    final orderRepository = _FakeOrderRepository();
    controller = CartController(
      createOrder: CreateOrderUseCase(orderRepository),
      addItems: AddOrderItemsUseCase(orderRepository),
      sendToKitchen: SendToKitchenUseCase(orderRepository),
      getSettings: GetSettingsUseCase(_FakeSettingsRepository()),
    );
  });

  group('CartController', () {
    test('เริ่มต้นตะกร้าว่าง', () {
      expect(controller.isEmpty, isTrue);
      expect(controller.totalQuantity, 0);
      expect(controller.subtotal, 0);
    });

    test(
      'เพิ่มเมนูซ้ำที่ตัวเลือกเหมือนกัน จะรวมเป็นบรรทัดเดียวและเพิ่มจำนวน',
      () {
        controller.addItem(padkrapao, options: [egg]);
        controller.addItem(padkrapao, quantity: 2, options: [egg]);

        expect(controller.lines.length, 1);
        expect(controller.lines.first.quantity, 3);
        expect(controller.subtotal, 270); // (75 + 15) x 3
      },
    );

    test('เพิ่มเมนูเดียวกันแต่โน้ตต่างกัน จะแยกเป็นคนละบรรทัด', () {
      controller.addItem(padkrapao);
      controller.addItem(padkrapao, note: 'ไม่ใส่ผัก');

      expect(controller.lines.length, 2);
      expect(controller.totalQuantity, 2);
    });

    test('ปรับจำนวนเป็น 0 เท่ากับลบรายการนั้นออก', () {
      controller.addItem(padkrapao);
      controller.addItem(somtum);

      controller.updateQuantity(0, 0);

      expect(controller.lines.length, 1);
      expect(controller.lines.first.menuItem.id, somtum.id);
    });

    test('ล้างตะกร้าแล้วต้องไม่เหลือรายการ', () {
      controller.addItem(padkrapao);
      controller.addItem(somtum);

      controller.clear();

      expect(controller.isEmpty, isTrue);
    });

    test('จำนวนลูกค้าถูกจำกัดไม่ให้ต่ำกว่า 1', () {
      controller.setGuestCount(0);
      expect(controller.guestCount.value, 1);

      controller.setGuestCount(8);
      expect(controller.guestCount.value, 8);
    });

    test('ยอดตัวอย่างคิด service charge และ VAT ตามค่าตั้งค่าเริ่มต้น', () {
      controller.addItem(padkrapao, quantity: 2); // 150

      final preview = controller.preview;

      expect(preview.subtotal, 150);
      expect(preview.serviceCharge, 15);
      expect(preview.total, 176.55);
    });
  });
}

/// Failure ตัวอย่างสำหรับ repository ปลอม
class UnexpectedFailureStub extends UnexpectedFailure {
  const UnexpectedFailureStub() : super('ไม่ได้ใช้งานในเทสต์นี้');
}
