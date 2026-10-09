// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/app/routes/app_routes.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/network/socket_client.dart';
import 'package:payneat_pos/core/services/session_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/repositories/order_repository.dart';
import 'package:payneat_pos/features/order/domain/usecases/order_usecases.dart';
import 'package:payneat_pos/features/order/presentation/controllers/order_detail_controller.dart';

/// ยกเลิกออเดอร์ที่ร้านยังถือเงินไว้ (T08 #100, DECISIONS #77 D2): เซิร์ฟเวอร์ตอบ `REFUND_REQUIRED` แอปต้องบอกเหตุผล
/// และพาไปหน้าชำระเงินที่คืนเงินได้ ไม่ใช่แค่ข้อความ error แล้วจบ
class _FakeOrderRepository implements OrderRepository {
  Result<Order> nextCancelResult = Result.success(_order(status: 'cancelled'));
  int getOrderCalls = 0;

  @override
  Future<Result<Order>> cancelOrder(int orderId, String reason) async =>
      nextCancelResult;

  @override
  Future<Result<Order>> getOrder(int id) async {
    getOrderCalls++;
    return Result.success(_order());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Order _order({String status = 'open'}) => Order(
  id: 1,
  code: 'A001',
  type: 'dine_in',
  status: status,
  subtotal: 211.86,
  total: 211.86,
  items: const [],
);

void main() {
  late _FakeOrderRepository repository;
  late OrderDetailController controller;

  Future<void> pumpApp(WidgetTester tester) async {
    repository = _FakeOrderRepository();
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
      previewMerge: PreviewMergeUseCase(repository),
      redeemPromotionCode: RedeemPromotionCodeUseCase(repository),
      removePromotion: RemovePromotionUseCase(repository),
      getEligiblePromotions: GetEligiblePromotionsUseCase(repository),
      session: SessionService(
        storage: StorageService.memory(),
        socket: SocketClient(),
      ),
    );
    addTearDown(Get.reset);
    addTearDown(controller.onClose);
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(body: Text('order-detail')),
        getPages: [
          GetPage(
            name: AppRoutes.checkout,
            page: () => const Scaffold(body: Text('checkout-page')),
          ),
        ],
      ),
    );
    // onInit อ่าน orderId จาก Get.arguments (ไม่มี route จริง → 0) แล้วโหลดออเดอร์ครั้งแรก
    controller.onInit();
    await tester.pumpAndSettle();
  }

  const refundMessage =
      'ออเดอร์นี้รับเงินไว้แล้ว 100 บาท ต้องคืนเงินให้ครบก่อนจึงจะยกเลิกได้';

  testWidgets(
    'REFUND_REQUIRED → บอกเหตุผล แล้วกด "ไปหน้าคืนเงิน" พาไปหน้าชำระเงิน ออเดอร์ไม่ถูกเปลี่ยนเป็นยกเลิก',
    (tester) async {
      await pumpApp(tester);
      repository.nextCancelResult = Result.failure(
        const ServerFailure(
          refundMessage,
          statusCode: 409,
          code: 'REFUND_REQUIRED',
        ),
      );

      final pending = controller.cancelOrder('ลูกค้าเปลี่ยนใจ');
      await tester.pumpAndSettle();

      expect(
        find.text('order_cancel_refund_required_title'.tr),
        findsOneWidget,
      );
      expect(find.textContaining(refundMessage), findsOneWidget);
      expect(
        find.textContaining('order_cancel_refund_required_hint'.tr),
        findsOneWidget,
      );
      expect(controller.order.value?.isCancelled ?? false, isFalse);

      await tester.tap(find.text('order_cancel_go_refund'.tr));
      await tester.pumpAndSettle();
      expect(find.text('checkout-page'), findsOneWidget);

      Get.back<void>();
      await tester.pumpAndSettle();
      await pending;
      expect(
        repository.getOrderCalls,
        2,
        reason: 'กลับจากหน้าคืนเงินแล้วโหลดออเดอร์ใหม่',
      );
    },
  );

  testWidgets('REFUND_REQUIRED แล้วกดปิด → ไม่ไปไหน', (tester) async {
    await pumpApp(tester);
    repository.nextCancelResult = Result.failure(
      const ServerFailure(
        refundMessage,
        statusCode: 409,
        code: 'REFUND_REQUIRED',
      ),
    );

    final pending = controller.cancelOrder('ลูกค้าเปลี่ยนใจ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('common_cancel'.tr));
    await tester.pumpAndSettle();
    await pending;

    expect(find.text('checkout-page'), findsNothing);
    expect(find.text('order-detail'), findsOneWidget);
  });

  testWidgets('ยกเลิกได้ → ออเดอร์เป็นยกเลิก', (tester) async {
    await pumpApp(tester);

    final pending = controller.cancelOrder('ลูกค้าเปลี่ยนใจ');
    await tester.pumpAndSettle();
    await pending;

    expect(controller.order.value?.isCancelled, isTrue);
    expect(find.text('order_cancel_refund_required_title'.tr), findsNothing);
  });
}
