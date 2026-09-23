import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/menu/domain/entities/category.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/entities/order_item_payload.dart';
import 'package:payneat_pos/features/self_order/domain/entities/self_order_table.dart';
import 'package:payneat_pos/features/self_order/domain/repositories/self_order_repository.dart';
import 'package:payneat_pos/features/self_order/domain/usecases/add_self_order_items_usecase.dart';
import 'package:payneat_pos/features/self_order/domain/usecases/get_self_order_menu_usecase.dart';
import 'package:payneat_pos/features/self_order/domain/usecases/get_self_order_table_usecase.dart';
import 'package:payneat_pos/features/self_order/presentation/controllers/self_order_controller.dart';

class _FakeSelfOrderRepository implements SelfOrderRepository {
  Result<({SelfOrderTable table, Order? order})> nextGetTableResult =
      Result.success((table: _table(), order: null));
  Result<({List<Category> categories, List<MenuItem> items})>
  nextGetMenuResult = Result.success((categories: const [], items: const []));
  Result<Order> nextAddItemsResult = Result.success(_order());

  @override
  Future<Result<({SelfOrderTable table, Order? order})>> getTable(
    String qrToken,
  ) async => nextGetTableResult;

  @override
  Future<Result<({List<Category> categories, List<MenuItem> items})>> getMenu(
    String qrToken,
  ) async => nextGetMenuResult;

  @override
  Future<Result<Order>> addItems(
    String qrToken,
    List<OrderItemPayload> items,
  ) async => nextAddItemsResult;
}

SelfOrderTable _table({int id = 1}) =>
    SelfOrderTable(id: id, name: 'A$id', zone: 'โซนในร้าน');

Order _order({int id = 1}) => Order(
  id: id,
  code: 'ORD$id',
  type: 'dine_in',
  status: 'open',
  subtotal: 0,
  total: 0,
);

MenuItem _menuItem(int id, {int categoryId = 1, double price = 50}) =>
    MenuItem(id: id, categoryId: categoryId, name: 'เมนู $id', price: price);

/// ผูก qrToken ตรงกับที่ onInit() จะอ่านจาก Get.parameters (ดู
/// self_order_controller.dart#onInit) — Get.parameters มี setter สาธารณะจริง (ไม่เหมือน
/// Get.routing ทั่วไป) จึงตั้งค่าตรงๆ ในเทสต์ได้โดยไม่ต้องมี route/widget tree จริง
void _setRouteQrToken(String qrToken) {
  Get.parameters = {'qrToken': qrToken};
}

void main() {
  late _FakeSelfOrderRepository repository;
  late SelfOrderController controller;

  setUp(() {
    repository = _FakeSelfOrderRepository();
    controller = SelfOrderController(
      getTableUseCase: GetSelfOrderTableUseCase(repository),
      getMenuUseCase: GetSelfOrderMenuUseCase(repository),
      addItemsUseCase: AddSelfOrderItemsUseCase(repository),
    );
  });

  tearDown(() {
    controller.onClose();
    Get.parameters = {};
  });

  group('SelfOrderController', () {
    // addToCart เส้นทางที่มีตัวเลือก (requiresSelection == true) เปิด OptionSelectionSheet
    // ผ่าน Get.bottomSheet โดยตรง และ submitCart ทุกเส้นทางเรียก AppDialogs.success/error
    // จึงไม่ครอบคลุมในเทสต์ระดับ unit นี้ (ดู docs/CODING_STANDARDS.md หัวข้อ 6.2)

    test(
      'onInit ไม่มี qrToken ในลิงก์ → ตั้ง errorMessage ทันทีโดยไม่เรียก repository',
      () async {
        _setRouteQrToken('');
        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        expect(controller.qrToken, isEmpty);
        expect(controller.errorMessage.value, isNotNull);
        expect(controller.isLoading.value, isFalse);
        expect(controller.table.value, isNull);
      },
    );

    test('onInit มี qrToken จริง → โหลดโต๊ะและเมนูสำเร็จ', () async {
      repository.nextGetTableResult = Result.success((
        table: _table(id: 9),
        order: _order(id: 5),
      ));
      repository.nextGetMenuResult = Result.success((
        categories: [const Category(id: 1, name: 'อาหารจานเดียว')],
        items: [_menuItem(1), _menuItem(2, categoryId: 2)],
      ));

      _setRouteQrToken('demo-table-9');
      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.qrToken, 'demo-table-9');
      expect(controller.table.value?.id, 9);
      expect(controller.currentOrder.value?.id, 5);
      expect(controller.items.length, 2);
      expect(controller.categories.length, 1);
      expect(controller.errorMessage.value, isNull);
      expect(controller.isLoading.value, isFalse);
    });

    test(
      'load ล้มเหลวตอนหาโต๊ะ (qrToken ผิด/โต๊ะปิดใช้งาน) → ตั้ง errorMessage',
      () async {
        repository.nextGetTableResult = Result.failure(
          const ServerFailure('ไม่พบโต๊ะนี้', statusCode: 404),
        );

        _setRouteQrToken('bad-token');
        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        expect(controller.errorMessage.value, 'ไม่พบโต๊ะนี้');
        expect(controller.table.value, isNull);
        // 404 = ลิงก์ตายแล้ว กดลองใหม่ไม่มีวันสำเร็จ หน้าจอต้องรู้เพื่อซ่อนปุ่มลองใหม่
        expect(controller.isLinkProblem.value, isTrue);
      },
    );

    test(
      'รูปแบบ token ผิด (backend ตอบ 400) ถือเป็นลิงก์เสีย — เช่นลิงก์ถูกตัดท้ายตอนส่งต่อทาง LINE',
      () async {
        repository.nextGetTableResult = Result.failure(
          const ValidationFailure('ข้อมูลที่ส่งมาไม่ถูกต้อง'),
        );

        _setRouteQrToken('3f2a9c1e-77b0-4d');
        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        // เดิมนับแค่ 404 — ลิงก์แบบนี้เลยขึ้นหน้า "ไม่มีอินเทอร์เน็ต" พร้อมปุ่มลองใหม่ที่ไม่มีวันสำเร็จ
        expect(controller.isLinkProblem.value, isTrue);
      },
    );

    test(
      'เน็ตสะดุด (ไม่ใช่ 404) ต้องไม่ถูกมองว่าเป็นลิงก์เสีย — ยังให้กดลองใหม่ได้',
      () async {
        repository.nextGetTableResult = Result.failure(
          NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
        );

        _setRouteQrToken('demo-table-1');
        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
        expect(controller.isLinkProblem.value, isFalse);
      },
    );

    test('ลิงก์ไม่มี qrToken เลย ถือเป็นลิงก์เสียเช่นกัน', () async {
      _setRouteQrToken('');
      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.isLinkProblem.value, isTrue);
    });

    test(
      'โหลดโต๊ะสำเร็จแต่โหลดเมนูล้มเหลว → ยังเห็นโต๊ะ แต่ตั้ง errorMessage จากเมนู',
      () async {
        repository.nextGetTableResult = Result.success((
          table: _table(),
          order: null,
        ));
        repository.nextGetMenuResult = Result.failure(
          NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
        );

        _setRouteQrToken('demo-table-1');
        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        expect(controller.table.value, isNotNull);
        expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
      },
    );

    test('filteredItems กรองตามหมวดที่เลือก', () async {
      repository.nextGetMenuResult = Result.success((
        categories: const [],
        items: [
          _menuItem(1, categoryId: 1),
          _menuItem(2, categoryId: 2),
          _menuItem(3, categoryId: 1),
        ],
      ));
      _setRouteQrToken('t');
      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.filteredItems.length, 3);

      controller.selectCategory(1);
      expect(controller.filteredItems.map((i) => i.id), [1, 3]);

      controller.selectCategory(null);
      expect(controller.filteredItems.length, 3);
    });

    test(
      'addToCart รายการที่ไม่มีตัวเลือก (requiresSelection == false) ใส่ตะกร้าทันที 1 ที่',
      () async {
        _setRouteQrToken('t');
        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        await controller.addToCart(_menuItem(1, price: 40));
        await controller.addToCart(_menuItem(2, price: 60));

        expect(controller.cart.length, 2);
        expect(controller.cartItemCount, 2);
        expect(controller.cartSubtotalPreview, 100);
      },
    );

    test(
      'กดเมนูเดิมซ้ำรวมเป็นบรรทัดเดียวแล้วบวกจำนวน ไม่ขึ้นบรรทัดใหม่ (กฎเดียวกับตะกร้าพนักงาน)',
      () async {
        _setRouteQrToken('t');
        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        await controller.addToCart(_menuItem(1, price: 40));
        await controller.addToCart(_menuItem(1, price: 40));
        await controller.addToCart(_menuItem(2, price: 60));

        expect(controller.cart.length, 2);
        expect(controller.cart.first.quantity, 2);
        expect(controller.cartItemCount, 3);
        expect(controller.cartSubtotalPreview, 140);
      },
    );

    test('updateCartQuantity ลดเหลือ 0 = เอาบรรทัดออกจากตะกร้าไปเลย', () async {
      _setRouteQrToken('t');
      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      await controller.addToCart(_menuItem(1, price: 40));
      await controller.addToCart(_menuItem(2, price: 60));

      controller.updateCartQuantity(0, 3);
      expect(controller.cart.first.quantity, 3);
      expect(controller.cartSubtotalPreview, 180);

      controller.updateCartQuantity(0, 0);
      expect(controller.cart.length, 1);
      expect(controller.cart.first.menuItem.id, 2);

      // index ที่ไม่มีจริงต้องไม่พังและไม่แตะตะกร้า
      controller.updateCartQuantity(9, 5);
      expect(controller.cart.length, 1);
    });

    test('removeCartLine ลบเฉพาะรายการที่ระบุ index', () async {
      _setRouteQrToken('t');
      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      await controller.addToCart(_menuItem(1, price: 40));
      await controller.addToCart(_menuItem(2, price: 60));
      controller.removeCartLine(0);

      expect(controller.cart.length, 1);
      expect(controller.cart.first.menuItem.id, 2);
    });
  });
}
