import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/network/socket_client.dart';
import 'package:payneat_pos/core/printing/receipt_printer_service.dart';
import 'package:payneat_pos/core/services/printer_settings_service.dart';
import 'package:payneat_pos/core/services/session_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/auth/domain/entities/user.dart';
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

Receipt _receipt({
  List<Payment> payments = const [],
  List<Refund> refunds = const [],
}) => Receipt(
  storeName: 'ร้านทดสอบ',
  currency: 'THB',
  vatRate: 0.07,
  serviceChargeRate: 0,
  payments: payments,
  refunds: refunds,
  refundedTotal: refunds.fold(0, (sum, r) => sum + r.amount),
);

// User.== เทียบแค่ id (เหมือน Order — ดู docs/CODING_STANDARDS.md หัวข้อ 3.5)
// ต้องใช้ id ต่างกันในแต่ละครั้งที่ session.start() ไม่งั้น Rxn มองว่า "ค่าเดิม" แล้วข้าม
// การอัปเดตจริง (ดู RxImpl.value setter) ทำให้ role เก่าค้างอยู่
User _user({int id = 1, String role = UserRole.waiter}) =>
    User(id: id, name: 'ทดสอบ', username: 'test', role: role, isActive: true);

void main() {
  late _FakePaymentRepository repository;
  late SessionService session;
  late ReceiptController controller;

  setUp(() {
    repository = _FakePaymentRepository();
    session = SessionService(
      storage: StorageService.memory(),
      socket: SocketClient(),
    );
    controller = ReceiptController(
      getReceipt: GetReceiptUseCase(repository),
      refundPayment: RefundPaymentUseCase(repository),
      session: session,
      printerSettings: PrinterSettingsService(storage: StorageService.memory()),
      printerService: ReceiptPrinterService(),
    );
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

    test(
      'canRefund อ่านสิทธิ์จากผู้ใช้ปัจจุบันในเซสชัน (manager ขึ้นไปเท่านั้น)',
      () {
        expect(controller.canRefund, isFalse);

        session.start(
          user: _user(id: 1, role: UserRole.cashier),
          token: 't',
        );
        expect(controller.canRefund, isFalse);

        session.start(
          user: _user(id: 2, role: UserRole.manager),
          token: 't',
        );
        expect(controller.canRefund, isTrue);
      },
    );

    test(
      'refundableAmount หักยอดที่คืนไปแล้วออกจากยอดจ่ายของ payment นั้น',
      () async {
        const payment = Payment(id: 9, orderId: 1, method: 'cash', amount: 100);
        repository.nextReceiptResult = Result.success((
          receipt: _receipt(
            payments: const [payment],
            refunds: const [
              Refund(
                id: 1,
                paymentId: 9,
                orderId: 1,
                amount: 30,
                reason: 'คืนบางส่วน',
              ),
            ],
          ),
          order: _order(),
        ));
        controller.onInit();
        await controller.load();

        expect(controller.refundableAmount(payment), 70);
      },
    );

    // submitRefund ทั้งสองผลลัพธ์ (สำเร็จ/ล้มเหลว) แตะ AppDialogs เสมอ (ไม่มี guard
    // ให้ return ก่อนแบบ submit() ของ checkout) จึงไม่ครอบคลุมในเทสต์ระดับ unit นี้
    // (ดู docs/CODING_STANDARDS.md — รูปแบบเดียวกับ checkout_controller_test.dart)

    test(
      'printerConfigured อ่านจาก PrinterSettingsService — ค่าเริ่มต้นยังไม่ได้ตั้งค่า',
      () {
        expect(controller.printerConfigured, isFalse);
      },
    );

    test(
      'printReceipt ก่อนโหลดใบเสร็จสำเร็จ (order/receipt ยังเป็น null) → ไม่ทำอะไรและไม่ throw',
      () async {
        // ไม่เรียก onInit()/load() จึง order.value และ receipt.value ยังเป็น null
        // ครอบคลุมเฉพาะ guard นี้ตามธรรมเนียมโปรเจกต์ (path ที่ทำสำเร็จแตะ AppDialogs
        // เหมือน submitRefund ด้านบน จึงไม่ครอบคลุมในเทสต์ระดับ unit)
        await expectLater(controller.printReceipt(), completes);
        expect(controller.isPrinting.value, isFalse);
      },
    );
  });
}
