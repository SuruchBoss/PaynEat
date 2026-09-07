import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/report/domain/entities/report.dart';
import 'package:payneat_pos/features/report/domain/repositories/report_repository.dart';
import 'package:payneat_pos/features/report/domain/usecases/report_usecases.dart';
import 'package:payneat_pos/features/report/presentation/controllers/report_controller.dart';

class _FakeReportRepository implements ReportRepository {
  Result<SalesSummary> nextSummaryResult = Result.success(SalesSummary.empty);
  Result<List<TopItem>> nextTopItemsResult = const Result.success([]);
  Result<List<DailySales>> nextSalesByDayResult = const Result.success([]);

  @override
  Future<Result<SalesSummary>> getSummary({String? from, String? to}) async =>
      nextSummaryResult;

  @override
  Future<Result<List<TopItem>>> getTopItems({
    String? from,
    String? to,
    int limit = 10,
  }) async => nextTopItemsResult;

  @override
  Future<Result<List<DailySales>>> getSalesByDay({
    String? from,
    String? to,
  }) async => nextSalesByDayResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SalesSummary _summary({int orderCount = 1}) => SalesSummary(
  from: '2026-09-01',
  to: '2026-09-07',
  orderCount: orderCount,
  guestCount: 2,
  subtotal: 100,
  discount: 0,
  serviceCharge: 0,
  vat: 7,
  netSales: 107,
  averagePerOrder: 107,
  averagePerGuest: 53.5,
);

void main() {
  late _FakeReportRepository repository;
  late ReportController controller;

  setUp(() {
    repository = _FakeReportRepository();
    controller = ReportController(
      getSummary: GetSalesSummaryUseCase(repository),
      getTopItems: GetTopItemsUseCase(repository),
      getSalesByDay: GetSalesByDayUseCase(repository),
    );
  });

  tearDown(() => controller.onClose());

  group('ReportController', () {
    test('onInit เลือกช่วง "วันนี้" เป็นค่าเริ่มต้น และ from == to', () {
      controller.onInit();

      expect(controller.range.value, ReportRange.today);
      expect(controller.from, controller.to);
    });

    test('selectRange(last7Days) → from ย้อนหลัง 6 วันจาก to', () {
      controller.onInit();

      controller.selectRange(ReportRange.last7Days);

      expect(controller.range.value, ReportRange.last7Days);
      expect(controller.to.difference(controller.from).inDays, 6);
    });

    test('selectRange(thisMonth) → from คือวันที่ 1 ของเดือนนี้', () {
      controller.onInit();

      controller.selectRange(ReportRange.thisMonth);

      final now = DateTime.now();
      expect(controller.from, DateTime(now.year, now.month));
    });

    test('setCustomRange → ตั้งช่วงกำหนดเองและโหลดข้อมูลใหม่', () async {
      controller.onInit();
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 31);
      repository.nextSummaryResult = Result.success(_summary(orderCount: 9));

      controller.setCustomRange(start, end);
      await Future<void>.delayed(Duration.zero);

      expect(controller.range.value, ReportRange.custom);
      expect(controller.from, start);
      expect(controller.to, end);
      expect(controller.summary.value.orderCount, 9);
    });

    test(
      'load สำเร็จ → เติม summary, topItems และ dailySales ทั้ง 3 อย่าง',
      () async {
        controller.onInit();
        repository.nextSummaryResult = Result.success(_summary(orderCount: 5));
        repository.nextTopItemsResult = const Result.success([
          TopItem(name: 'ผัดไทย', quantity: 10, revenue: 500),
        ]);
        repository.nextSalesByDayResult = const Result.success([
          DailySales(day: '2026-09-07', orderCount: 5, total: 500),
        ]);

        await controller.load();

        expect(controller.summary.value.orderCount, 5);
        expect(controller.topItems.map((t) => t.name), ['ผัดไทย']);
        expect(controller.dailySales.map((d) => d.day), ['2026-09-07']);
        expect(controller.isLoading.value, isFalse);
        expect(controller.errorMessage.value, isNull);
      },
    );

    test('load เมื่อ summary ล้มเหลว → ตั้ง errorMessage', () async {
      controller.onInit();
      repository.nextSummaryResult = const Result.failure(
        NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
      );

      await controller.load();

      expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
    });

    test(
      'load เมื่อ topItems/dailySales ล้มเหลว → ไม่ตั้ง errorMessage (กลืน error เงียบ ๆ)',
      () async {
        controller.onInit();
        repository.nextSummaryResult = Result.success(_summary());
        repository.nextTopItemsResult = const Result.failure(
          NetworkFailure('พัง'),
        );
        repository.nextSalesByDayResult = const Result.failure(
          NetworkFailure('พัง'),
        );

        await controller.load();

        expect(controller.errorMessage.value, isNull);
        expect(controller.topItems, isEmpty);
        expect(controller.dailySales, isEmpty);
      },
    );
  });
}
