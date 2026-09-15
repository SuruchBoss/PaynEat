import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/network/socket_client.dart';
import 'package:payneat_pos/core/services/session_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/auth/domain/entities/user.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/entities/order_item.dart';
import 'package:payneat_pos/features/order/domain/repositories/order_repository.dart';
import 'package:payneat_pos/features/order/domain/usecases/order_usecases.dart';
import 'package:payneat_pos/features/order/presentation/controllers/order_detail_controller.dart';

class _FakeOrderRepository implements OrderRepository {
  Result<Order> nextGetOrderResult = Result.success(_order());
  Result<Order> nextUpdateItemResult = Result.success(_order());
  Result<Order> nextUpdateItemStatusResult = Result.success(_order());

  @override
  Future<Result<Order>> getOrder(int id) async => nextGetOrderResult;

  @override
  Future<Result<Order>> updateItem(
    int orderId,
    int itemId, {
    int? quantity,
    String? note,
  }) async => nextUpdateItemResult;

  @override
  Future<Result<Order>> updateItemStatus(
    int orderId,
    int itemId,
    String status,
  ) async => nextUpdateItemStatusResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Order _order({int id = 1, List<OrderItem> items = const []}) => Order(
  id: id,
  code: 'A001',
  type: 'dine_in',
  status: 'open',
  subtotal: 100,
  total: 100,
  items: items,
);

OrderItem _item(
  int id, {
  int orderId = 1,
  String status = OrderItemStatus.pending,
  int quantity = 1,
}) => OrderItem(
  id: id,
  orderId: orderId,
  name: 'ข้าวผัด',
  unitPrice: 50,
  quantity: quantity,
  lineTotal: 50.0 * quantity,
  status: status,
);

User _user({String role = UserRole.waiter}) =>
    User(id: 1, name: 'ทดสอบ', username: 'test', role: role, isActive: true);

void main() {
  late _FakeOrderRepository repository;
  late SessionService session;
  late OrderDetailController controller;

  setUp(() {
    repository = _FakeOrderRepository();
    session = SessionService(
      storage: StorageService.memory(),
      socket: SocketClient(),
    );
    controller = OrderDetailController(
      getOrder: GetOrderUseCase(repository),
      sendToKitchen: SendToKitchenUseCase(repository),
      updateItem: UpdateOrderItemUseCase(repository),
      removeItem: RemoveOrderItemUseCase(repository),
      updateItemStatus: UpdateOrderItemStatusUseCase(repository),
      applyDiscount: ApplyDiscountUseCase(repository),
      cancelOrder: CancelOrderUseCase(repository),
      moveOrderTable: MoveOrderTableUseCase(repository),
      mergeOrders: MergeOrdersUseCase(repository),
      redeemPromotionCode: RedeemPromotionCodeUseCase(repository),
      removePromotion: RemovePromotionUseCase(repository),
      getEligiblePromotions: GetEligiblePromotionsUseCase(repository),
      session: session,
    );
  });

  tearDown(() => controller.onClose());

  group('OrderDetailController', () {
    // sendToKitchen/removeItem/cancelItem/applyDiscount/cancelOrder ทุกเส้นทาง และ path
    // ล้มเหลวของ _run ทั้งหมด เรียก AppDialogs โดยตรง จึงไม่ครอบคลุมในเทสต์ระดับ unit นี้
    // (ดู docs/CODING_STANDARDS.md) — ทดสอบเฉพาะ path ที่ไม่แตะ Get.*/AppDialogs

    test(
      'onInit อ่าน orderId จาก Get.arguments (ไม่มี route จริง → 0) แล้วโหลดออเดอร์',
      () async {
        repository.nextGetOrderResult = Result.success(_order(id: 8));

        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        expect(controller.orderId, 0);
        expect(controller.order.value?.id, 8);
      },
    );

    test('load สำเร็จ → เติมออเดอร์และปิด loading', () async {
      controller.onInit();
      await Future<void>.delayed(Duration.zero);
      repository.nextGetOrderResult = Result.success(_order(id: 3));

      await controller.load();

      expect(controller.order.value?.id, 3);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isNull);
    });

    test('load ล้มเหลว → ตั้ง errorMessage', () async {
      controller.onInit();
      await Future<void>.delayed(Duration.zero);
      repository.nextGetOrderResult = Result.failure(
        NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
      );

      await controller.load();

      expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
    });

    test(
      // ล็อกบั๊กที่เคยเกิดจริง (ดู docs/CODING_STANDARDS.md หัวข้อ 3.5): load()
      // ถูกเรียกซ้ำจาก realtime update ด้วย order id เดิมเสมอ ถ้าไม่เคลียร์
      // order.value เป็น null ก่อน GetX จะมองว่า "ค่าไม่เปลี่ยน" แล้วข้าม assignment
      'load เรียกซ้ำด้วย order id เดิม (เช่น realtime update) ต้องอัปเดตรายการใหม่จริง',
      () async {
        controller.onInit();
        await Future<void>.delayed(Duration.zero);
        repository.nextGetOrderResult = Result.success(
          _order(items: [_item(1, status: OrderItemStatus.pending)]),
        );
        await controller.load();
        expect(
          controller.order.value?.items.single.status,
          OrderItemStatus.pending,
        );

        repository.nextGetOrderResult = Result.success(
          _order(items: [_item(1, status: OrderItemStatus.cooking)]),
        );
        await controller.load();

        expect(
          controller.order.value?.items.single.status,
          OrderItemStatus.cooking,
        );
      },
    );

    test(
      'canManage / canCollectPayment อ่านสิทธิ์จากผู้ใช้ปัจจุบันในเซสชัน',
      () {
        expect(controller.canManage, isFalse);
        expect(controller.canCollectPayment, isFalse);

        session.start(
          user: _user(role: UserRole.manager),
          token: 't',
        );
        expect(controller.canManage, isTrue);

        session.start(
          user: _user(role: UserRole.cashier),
          token: 't',
        );
        expect(controller.canCollectPayment, isTrue);
      },
    );

    test(
      // Order.== เทียบแค่ id ทำให้ GetX คิดว่าค่าเดิม "ไม่เปลี่ยน" ถ้าไม่รีเซ็ตเป็น null
      // ก่อน (ดูคอมเมนต์ใน _run) เทสต์นี้ล็อกพฤติกรรมว่าอัปเดตจริงแม้ id ออเดอร์เดิม
      'changeItemQuantity สำเร็จ → อัปเดตออเดอร์จากผลลัพธ์ (ไม่มี successMessage)',
      () async {
        controller.onInit();
        await Future<void>.delayed(Duration.zero);
        repository.nextUpdateItemResult = Result.success(
          _order(items: [_item(1, quantity: 3)]),
        );

        await controller.changeItemQuantity(_item(1), 3);

        expect(controller.order.value?.items.single.quantity, 3);
        expect(controller.isBusy.value, isFalse);
      },
    );

    test(
      'advanceItemStatus สำเร็จ (ยังมีสถานะถัดไป) → อัปเดตออเดอร์จากผลลัพธ์',
      () async {
        controller.onInit();
        await Future<void>.delayed(Duration.zero);
        repository.nextUpdateItemStatusResult = Result.success(
          _order(items: [_item(1, status: OrderItemStatus.cooking)]),
        );

        await controller.advanceItemStatus(
          _item(1, status: OrderItemStatus.pending),
        );

        expect(
          controller.order.value?.items.single.status,
          OrderItemStatus.cooking,
        );
      },
    );

    test(
      'advanceItemStatus เมื่อไม่มีสถานะถัดไป (served) → ไม่ทำอะไร',
      () async {
        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        await controller.advanceItemStatus(
          _item(1, status: OrderItemStatus.served),
        );

        expect(controller.order.value?.id, 1);
        expect(controller.isBusy.value, isFalse);
      },
    );
  });
}
