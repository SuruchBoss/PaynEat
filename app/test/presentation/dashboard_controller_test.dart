import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/network/socket_client.dart';
import 'package:payneat_pos/core/services/session_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/report/domain/entities/report.dart';
import 'package:payneat_pos/features/report/domain/repositories/report_repository.dart';
import 'package:payneat_pos/features/report/domain/usecases/report_usecases.dart';
import 'package:payneat_pos/features/report/presentation/controllers/dashboard_controller.dart';

class _FakeReportRepository implements ReportRepository {
  Result<DashboardData> nextDashboardResult = Result.success(
    DashboardData.empty,
  );

  @override
  Future<Result<DashboardData>> getDashboard() async => nextDashboardResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DashboardData _dashboard({int orderCount = 3}) => DashboardData(
  today: SalesSummary(
    from: '2026-09-07',
    to: '2026-09-07',
    orderCount: orderCount,
    guestCount: 0,
    subtotal: 0,
    discount: 0,
    serviceCharge: 0,
    vat: 0,
    netSales: 0,
    averagePerOrder: 0,
    averagePerGuest: 0,
  ),
  live: const LiveCounters(
    openOrders: 2,
    occupiedTables: 1,
    totalTables: 5,
    pendingKitchenItems: 0,
  ),
);

void main() {
  late _FakeReportRepository repository;
  late SessionService session;
  late DashboardController controller;

  setUp(() {
    repository = _FakeReportRepository();
    session = SessionService(
      storage: StorageService.memory(),
      socket: SocketClient(),
    );
    controller = DashboardController(
      getDashboard: GetDashboardUseCase(repository),
      session: session,
    );
  });

  tearDown(() => controller.onClose());

  group('DashboardController', () {
    test('load สำเร็จ → เติมข้อมูล dashboard และปิด loading', () async {
      repository.nextDashboardResult = Result.success(_dashboard());

      await controller.load();

      expect(controller.data.value.today.orderCount, 3);
      expect(controller.data.value.live.totalTables, 5);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isNull);
    });

    test('load ล้มเหลว → ตั้ง errorMessage และคงข้อมูลเดิม', () async {
      repository.nextDashboardResult = Result.success(_dashboard());
      await controller.load();

      repository.nextDashboardResult = Result.failure(
        NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
      );
      await controller.load();

      expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
      expect(controller.data.value.today.orderCount, 3);
    });

    test('load(showLoader: false) ไม่เปิด isLoading ระหว่างโหลด', () async {
      controller.isLoading.value = false;
      repository.nextDashboardResult = Result.success(_dashboard());

      final future = controller.load(showLoader: false);
      expect(controller.isLoading.value, isFalse);
      await future;

      expect(controller.isLoading.value, isFalse);
    });

    test(
      'onInit โหลดข้อมูลและสมัคร realtime แล้ว onClose ยกเลิกได้โดยไม่โยน exception',
      () {
        expect(() => controller.onInit(), returnsNormally);
        expect(() => controller.onClose(), returnsNormally);
      },
    );
  });
}
