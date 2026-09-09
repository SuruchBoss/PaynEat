import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/entities/order_item.dart';
import 'package:payneat_pos/features/order/domain/repositories/order_repository.dart';
import 'package:payneat_pos/features/order/domain/usecases/order_usecases.dart';
import 'package:payneat_pos/features/payment/domain/entities/payment.dart';
import 'package:payneat_pos/features/payment/domain/repositories/payment_repository.dart';
import 'package:payneat_pos/features/payment/domain/usecases/payment_usecases.dart';
import 'package:payneat_pos/features/payment/presentation/controllers/split_bill_controller.dart';

class _FakeOrderRepository implements OrderRepository {
  Result<Order> nextGetOrderResult = Result.success(_order());

  @override
  Future<Result<Order>> getOrder(int id) async => nextGetOrderResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentRepository implements PaymentRepository {
  Result<SplitPreview> nextPreviewResult = Result.success(_preview());
  Result<({PaymentResult result, Order order})>? nextPayResult;
  int payCallCount = 0;

  @override
  Future<Result<SplitPreview>> getSplitPreview(
    int orderId,
    List<int> itemIds,
  ) async => nextPreviewResult;

  @override
  Future<Result<({PaymentResult result, Order order})>> pay({
    required int orderId,
    required String method,
    double? amount,
    List<int>? itemIds,
    double? received,
    String? reference,
  }) async {
    payCallCount++;
    return nextPayResult!;
  }

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
  String status = OrderItemStatus.pending,
  bool isPaid = false,
}) => OrderItem(
  id: id,
  orderId: 1,
  name: 'ข้าวผัด',
  unitPrice: 50,
  quantity: 1,
  lineTotal: 50,
  status: status,
  isPaid: isPaid,
);

SplitPreview _preview({
  double total = 50,
  double remaining = 100,
  bool isLastBatch = false,
}) => SplitPreview(
  orderId: 1,
  itemIds: const [1],
  subtotal: 50,
  discountAmount: 0,
  serviceCharge: 0,
  vat: 0,
  total: total,
  remaining: remaining,
  isLastBatch: isLastBatch,
);

void main() {
  late _FakeOrderRepository orderRepository;
  late _FakePaymentRepository paymentRepository;
  late SplitBillController controller;

  setUp(() {
    orderRepository = _FakeOrderRepository();
    paymentRepository = _FakePaymentRepository();
    controller = SplitBillController(
      getOrder: GetOrderUseCase(orderRepository),
      getSplitPreview: GetSplitPreviewUseCase(paymentRepository),
      pay: PayOrderUseCase(paymentRepository),
    );
  });

  tearDown(() => controller.onClose());

  group('SplitBillController', () {
    // submit() ทั้งสองผลลัพธ์ (สำเร็จ/ล้มเหลว) แตะ AppDialogs หรือ Get.offNamed
    // จึงไม่ครอบคลุมในเทสต์ระดับ unit นี้ (ดู docs/CODING_STANDARDS.md หัวข้อ 6.2)

    test(
      'onInit อ่าน orderId จาก Get.arguments (ไม่มี route จริง → 0) แล้วโหลดออเดอร์',
      () async {
        orderRepository.nextGetOrderResult = Result.success(_order(id: 9));

        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        expect(controller.orderId, 0);
        expect(controller.order.value?.id, 9);
      },
    );

    test('load สำเร็จ → เติมออเดอร์และปิด loading', () async {
      controller.onInit();
      await Future<void>.delayed(Duration.zero);
      orderRepository.nextGetOrderResult = Result.success(
        _order(items: [_item(1), _item(2, isPaid: true)]),
      );

      await controller.load();

      expect(controller.order.value?.items.length, 2);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isNull);
    });

    test('load ล้มเหลว → ตั้ง errorMessage', () async {
      controller.onInit();
      await Future<void>.delayed(Duration.zero);
      orderRepository.nextGetOrderResult = Result.failure(
        NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
      );

      await controller.load();

      expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
    });

    test(
      'unpaidItems กรองเฉพาะรายการที่ยังไม่ถูกจ่ายและยังไม่ถูกยกเลิก',
      () async {
        controller.onInit();
        await Future<void>.delayed(Duration.zero);
        orderRepository.nextGetOrderResult = Result.success(
          _order(
            items: [
              _item(1),
              _item(2, isPaid: true),
              _item(3, status: OrderItemStatus.cancelled),
            ],
          ),
        );

        await controller.load();

        expect(controller.unpaidItems.map((item) => item.id), [1]);
      },
    );

    test(
      'toggleItem สำเร็จ → ดึงยอดพรีวิวมาเก็บและตั้งยอดรับเงินเริ่มต้นให้พอดี',
      () async {
        controller.onInit();
        await Future<void>.delayed(Duration.zero);
        paymentRepository.nextPreviewResult = Result.success(
          _preview(total: 75),
        );

        await controller.toggleItem(1);

        expect(controller.selectedItemIds, {1});
        expect(controller.preview.value?.total, 75);
        expect(controller.received.value, 75);
        expect(controller.receivedController.text, '75.00');
      },
    );

    test(
      'toggleItem ครั้งที่สองกับ id เดิม → ยกเลิกการเลือกและล้างพรีวิว',
      () async {
        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        await controller.toggleItem(1);
        await controller.toggleItem(1);

        expect(controller.selectedItemIds, isEmpty);
        expect(controller.preview.value, isNull);
      },
    );

    test('canPay / change คำนวณเฉพาะตอนมีพรีวิวและเลือกรายการอยู่', () async {
      controller.onInit();
      await Future<void>.delayed(Duration.zero);
      expect(controller.canPay, isFalse, reason: 'ยังไม่เลือกรายการ');

      paymentRepository.nextPreviewResult = Result.success(
        _preview(total: 100),
      );
      await controller.toggleItem(1);

      controller.selectMethod(PaymentMethod.cash);
      controller.setReceived(50);
      expect(controller.canPay, isFalse, reason: 'รับเงินไม่พอ');
      expect(controller.change, 0);

      controller.setReceived(150);
      expect(controller.canPay, isTrue);
      expect(controller.change, 50);

      controller.selectMethod(PaymentMethod.qr);
      expect(controller.change, 0);
    });

    test('onReceivedChanged parse จากข้อความ แปลงไม่ได้ = 0', () {
      controller.onReceivedChanged('123.45');
      expect(controller.received.value, 123.45);

      controller.onReceivedChanged('ไม่ใช่ตัวเลข');
      expect(controller.received.value, 0);
    });
  });
}
