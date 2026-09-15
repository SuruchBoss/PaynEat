import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/network/socket_client.dart';
import 'package:payneat_pos/core/services/session_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/repositories/order_repository.dart';
import 'package:payneat_pos/features/order/domain/usecases/order_usecases.dart';
import 'package:payneat_pos/features/order/presentation/controllers/order_list_controller.dart';

/// repository ปลอมที่เก็บ filter ล่าสุดที่ถูกส่งเข้ามา และสลับผลลัพธ์ระหว่าง
/// success/failure ได้ตามที่แต่ละเทสต์ต้องการ
class _FakeOrderRepository implements OrderRepository {
  ({String? status, bool? activeOnly, String? dateFrom})? lastQuery;
  Result<({List<Order> orders, int total})> nextResult = const Result.success((
    orders: <Order>[],
    total: 0,
  ));

  @override
  Future<Result<({List<Order> orders, int total})>> getOrders({
    String? status,
    bool? activeOnly,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 30,
  }) async {
    lastQuery = (status: status, activeOnly: activeOnly, dateFrom: dateFrom);
    return nextResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Order _order(int id, {String status = OrderStatus.open}) => Order(
  id: id,
  code: 'A00$id',
  type: OrderType.dineIn,
  status: status,
  subtotal: 100,
  total: 117.7,
);

void main() {
  late _FakeOrderRepository repository;
  late OrderListController controller;

  setUp(() {
    repository = _FakeOrderRepository();
    final session = SessionService(
      storage: StorageService.memory(),
      socket: SocketClient(),
    );
    controller = OrderListController(
      getOrders: GetOrdersUseCase(repository),
      session: session,
    );
  });

  tearDown(() => controller.onClose());

  group('OrderListController', () {
    test('มีตัวกรองครบ 6 แบบ เริ่มจาก "กำลังดำเนินการ" (ไม่กรองสถานะ)', () {
      expect(OrderListController.filters.length, 6);
      expect(OrderListController.filters.first.value, isNull);
      expect(OrderListController.filters.first.label, 'กำลังดำเนินการ');
    });

    test('onInit โหลดออเดอร์ให้ทันทีและปิด loading เมื่อเสร็จ', () async {
      repository.nextResult = Result.success((orders: [_order(1)], total: 1));

      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.orders.length, 1);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isNull);
    });

    test(
      'load ล้มเหลว → ตั้ง errorMessage และไม่ล้างออเดอร์เดิมที่มีอยู่',
      () async {
        repository.nextResult = Result.success((orders: [_order(1)], total: 1));
        await controller.load();
        expect(controller.orders.length, 1);

        repository.nextResult = Result.failure(
          NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
        );
        await controller.load();

        expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
        expect(controller.orders.length, 1); // assignAll ไม่ถูกเรียกตอน failure
      },
    );

    test(
      'ตัวกรอง "กำลังดำเนินการ" (status null) ต้องส่ง activeOnly=true ไปด้วย',
      () async {
        controller.setFilter(null);
        await Future<void>.delayed(Duration.zero);

        expect(repository.lastQuery?.status, isNull);
        expect(repository.lastQuery?.activeOnly, isTrue);
        expect(repository.lastQuery?.dateFrom, isNull);
      },
    );

    test(
      'กรองสถานะ "ชำระแล้ว" ต้องจำกัดช่วงวันที่แค่วันนี้ (ไม่งั้นรายการยาวเกินใช้งานจริง)',
      () async {
        controller.setFilter(OrderStatus.paid);
        await Future<void>.delayed(Duration.zero);

        expect(repository.lastQuery?.status, OrderStatus.paid);
        expect(repository.lastQuery?.activeOnly, isNull);
        expect(repository.lastQuery?.dateFrom, isNotNull);
      },
    );

    test(
      'กรองสถานะที่ยังเปิดอยู่ (เช่น "อยู่ในครัว") ไม่จำกัดช่วงวันที่',
      () async {
        controller.setFilter(OrderStatus.inKitchen);
        await Future<void>.delayed(Duration.zero);

        expect(repository.lastQuery?.status, OrderStatus.inKitchen);
        expect(repository.lastQuery?.dateFrom, isNull);
      },
    );

    test('onInit แล้ว onClose ต้องไม่โยน exception (unsubscribe ครบ)', () {
      // เมธอดที่แตะ Get.toNamed (openOrder) ต้องมี GetMaterialApp จึงไม่ครอบคลุมในเทสต์นี้
      // แต่ life-cycle ของ realtime subscription (onInit ผูก → onClose เลิกผูก) ทดสอบได้ตรง ๆ
      expect(() => controller.onInit(), returnsNormally);
      expect(() => controller.onClose(), returnsNormally);
    });
  });
}
