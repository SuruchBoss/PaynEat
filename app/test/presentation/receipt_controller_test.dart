import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/payment/domain/entities/payment.dart';
import 'package:payneat_pos/features/payment/domain/repositories/payment_repository.dart';
import 'package:payneat_pos/features/payment/domain/usecases/payment_usecases.dart';
import 'package:payneat_pos/features/payment/presentation/controllers/receipt_controller.dart';

class _FakePaymentRepository implements PaymentRepository {
  Result<({Receipt receipt, Order order})> nextReceiptResult = Result.success((
    receipt: _receipt(),
    order: _order(),
  ));

  @override
  Future<Result<({Receipt receipt, Order order})>> getReceipt(
    int orderId,
  ) async => nextReceiptResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Order _order({int id = 1}) => Order(
  id: id,
  code: 'A001',
  type: 'dine_in',
  status: 'paid',
  subtotal: 100,
  total: 107,
);

Receipt _receipt() => const Receipt(
  storeName: 'ร้านทดสอบ',
  currency: 'THB',
  vatRate: 0.07,
  serviceChargeRate: 0,
  payments: [],
);

void main() {
  late _FakePaymentRepository repository;
  late ReceiptController controller;

  setUp(() {
    repository = _FakePaymentRepository();
    controller = ReceiptController(getReceipt: GetReceiptUseCase(repository));
  });

  tearDown(() => controller.onClose());

  group('ReceiptController', () {
    test('load สำเร็จ → เติมใบเสร็จและออเดอร์ ปิด loading', () async {
      controller.onInit();
      repository.nextReceiptResult = Result.success((
        receipt: _receipt(),
        order: _order(id: 5),
      ));

      await controller.load();

      expect(controller.order.value?.id, 5);
      expect(controller.receipt.value?.storeName, 'ร้านทดสอบ');
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isNull);
    });

    test('load ล้มเหลว → ตั้ง errorMessage และไม่เติมข้อมูล', () async {
      repository.nextReceiptResult = const Result.failure(
        NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
      );
      controller.onInit();

      await controller.load();

      expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
      expect(controller.order.value, isNull);
      expect(controller.receipt.value, isNull);
    });

    test(
      'onInit อ่าน Get.arguments ที่ไม่มี route จริง (ได้ orderId = 0) แล้วโหลดโดยไม่โยน exception',
      () {
        // ไม่มี GetMaterialApp ที่ pump จริง จึง Get.arguments เป็น null และ orderId
        // fallback เป็น 0 — ครอบคลุมเฉพาะ path นี้ตามธรรมเนียมของโปรเจกต์ (ดู docs/CODING_STANDARDS.md)
        expect(() => controller.onInit(), returnsNormally);
        expect(controller.orderId, 0);
      },
    );
  });
}
