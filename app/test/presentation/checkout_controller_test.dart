import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/repositories/order_repository.dart';
import 'package:payneat_pos/features/order/domain/usecases/order_usecases.dart';
import 'package:payneat_pos/features/payment/domain/entities/payment.dart';
import 'package:payneat_pos/features/payment/domain/repositories/payment_repository.dart';
import 'package:payneat_pos/features/payment/domain/usecases/payment_usecases.dart';
import 'package:payneat_pos/features/payment/presentation/controllers/checkout_controller.dart';
import 'package:payneat_pos/features/shift/domain/entities/shift.dart';
import 'package:payneat_pos/features/shift/domain/repositories/shift_repository.dart';
import 'package:payneat_pos/features/shift/domain/usecases/shift_usecases.dart';

class _FakeOrderRepository implements OrderRepository {
  Result<Order> nextOrderResult = Result.success(_order());

  @override
  Future<Result<Order>> getOrder(int id) async => nextOrderResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentRepository implements PaymentRepository {
  Result<PaymentSummary> nextSummaryResult = Result.success(_summary());
  Result<({PaymentResult result, Order order})>? nextPayResult;
  int payCallCount = 0;

  @override
  Future<Result<PaymentSummary>> getSummary(int orderId) async =>
      nextSummaryResult;

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

class _FakeShiftRepository implements ShiftRepository {
  Result<Shift?> nextCurrentResult = Result.success(_openShift());

  @override
  Future<Result<Shift?>> getCurrent() async => nextCurrentResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Shift _openShift() => const Shift(
  id: 1,
  status: 'open',
  openedBy: 1,
  openedAt: '2026-01-01T00:00:00Z',
  openingCash: 2000,
);

Order _order({int id = 1, double total = 107}) => Order(
  id: id,
  code: 'A001',
  type: 'dine_in',
  status: 'open',
  subtotal: 100,
  total: total,
);

PaymentSummary _summary({double total = 107, double paid = 0}) =>
    PaymentSummary(
      orderId: 1,
      total: total,
      paid: paid,
      remaining: total - paid,
    );

void main() {
  late _FakeOrderRepository orderRepository;
  late _FakePaymentRepository paymentRepository;
  late _FakeShiftRepository shiftRepository;
  late CheckoutController controller;

  setUp(() {
    orderRepository = _FakeOrderRepository();
    paymentRepository = _FakePaymentRepository();
    shiftRepository = _FakeShiftRepository();
    controller = CheckoutController(
      getOrder: GetOrderUseCase(orderRepository),
      getSummary: GetPaymentSummaryUseCase(paymentRepository),
      pay: PayOrderUseCase(paymentRepository),
      getCurrentShift: GetCurrentShiftUseCase(shiftRepository),
    );
  });

  tearDown(() => controller.onClose());

  group('CheckoutController', () {
    // submit() ทั้งสองผลลัพธ์ (สำเร็จ/ล้มเหลว) แตะ AppDialogs หรือ Get.offNamed
    // จึงไม่ครอบคลุมในเทสต์ระดับ unit นี้ ทดสอบเฉพาะ guard `if (!canPay) return;`
    // (ดู docs/CODING_STANDARDS.md)

    test(
      'onInit อ่าน orderId จาก Get.arguments (ไม่มี route จริง → 0) แล้วโหลดข้อมูล',
      () async {
        orderRepository.nextOrderResult = Result.success(_order(id: 9));
        paymentRepository.nextSummaryResult = Result.success(_summary());

        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        expect(controller.orderId, 0);
        expect(controller.order.value?.id, 9);
      },
    );

    test(
      'load สำเร็จ → เติมออเดอร์/สรุปยอด และตั้งยอดจ่ายเริ่มต้นเป็นยอดคงเหลือ',
      () async {
        orderRepository.nextOrderResult = Result.success(_order(total: 107));
        paymentRepository.nextSummaryResult = Result.success(
          _summary(total: 107, paid: 0),
        );

        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        expect(controller.order.value?.total, 107);
        expect(controller.remaining, 107);
        expect(controller.amount.value, 107);
        expect(controller.isLoading.value, isFalse);
      },
    );

    test('load ล้มเหลว → ตั้ง errorMessage', () async {
      orderRepository.nextOrderResult = Result.failure(
        NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
      );

      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
    });

    test('isCash / change คำนวณเฉพาะตอนจ่ายเงินสด', () async {
      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      controller.selectMethod(PaymentMethod.cash);
      controller.setAmount(100);
      controller.setReceived(150);
      expect(controller.isCash, isTrue);
      expect(controller.change, 50);

      controller.selectMethod(PaymentMethod.card);
      expect(controller.isCash, isFalse);
      expect(controller.change, 0);
    });

    test('canPay ต้องมากกว่า 0 ไม่เกินยอดคงเหลือ และเงินสดต้องรับพอ', () async {
      orderRepository.nextOrderResult = Result.success(_order(total: 100));
      paymentRepository.nextSummaryResult = Result.success(
        _summary(total: 100, paid: 0),
      );
      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      controller.selectMethod(PaymentMethod.cash);
      controller.setAmount(100);
      controller.setReceived(50);
      expect(controller.canPay, isFalse, reason: 'รับเงินไม่พอ');

      controller.setReceived(100);
      expect(controller.canPay, isTrue);

      controller.setAmount(0);
      expect(controller.canPay, isFalse, reason: 'ยอดจ่ายต้องมากกว่า 0');

      controller.setAmount(200);
      expect(controller.canPay, isFalse, reason: 'ห้ามจ่ายเกินยอดคงเหลือ');
    });

    test('setAmount ปัดทศนิยม 2 ตำแหน่งและอัปเดตข้อความในช่องกรอก', () async {
      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      controller.setAmount(99.999);

      expect(controller.amount.value, 100.0);
      expect(controller.amountController.text, '100.00');
    });

    test(
      'onAmountChanged/onReceivedChanged parse จากข้อความ แปลงไม่ได้ = 0',
      () {
        controller.onAmountChanged('123.45');
        expect(controller.amount.value, 123.45);

        controller.onAmountChanged('ไม่ใช่ตัวเลข');
        expect(controller.amount.value, 0);

        controller.onReceivedChanged('200');
        expect(controller.received.value, 200);
      },
    );

    test('roundedUpSuggestion ปัดยอดคงเหลือขึ้นเป็นหลักร้อยถัดไป', () async {
      orderRepository.nextOrderResult = Result.success(_order(total: 176.55));
      paymentRepository.nextSummaryResult = Result.success(
        _summary(total: 176.55, paid: 0),
      );
      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.roundedUpSuggestion, 200);
    });

    test(
      'submit เมื่อ canPay เป็นเท็จ → คืนทันทีโดยไม่เรียก pay use case',
      () async {
        controller.onInit();
        await Future<void>.delayed(Duration.zero);
        controller.setAmount(0);

        await controller.submit();

        expect(paymentRepository.payCallCount, 0);
      },
    );

    test(
      'ไม่มีกะเปิดอยู่ → hasOpenShift เป็นเท็จ และ canPay ถูกบล็อกเสมอ',
      () async {
        shiftRepository.nextCurrentResult = const Result.success(null);
        orderRepository.nextOrderResult = Result.success(_order(total: 100));
        paymentRepository.nextSummaryResult = Result.success(
          _summary(total: 100, paid: 0),
        );

        controller.onInit();
        await Future<void>.delayed(Duration.zero);
        controller.selectMethod(PaymentMethod.cash);
        controller.setAmount(100);
        controller.setReceived(100);

        expect(controller.hasOpenShift.value, isFalse);
        expect(controller.canPay, isFalse);
      },
    );

    test('มีกะเปิดอยู่ → hasOpenShift เป็นจริง', () async {
      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.hasOpenShift.value, isTrue);
    });
  });
}
