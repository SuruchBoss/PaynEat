import 'package:get/get.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/report.dart';
import '../../domain/usecases/report_usecases.dart';
import '../../../../core/utils/app_clock.dart';

/// ช่วงเวลาที่เลือกดูรายงาน
enum ReportRange { today, last7Days, thisMonth, custom }

/// รายงานยอดขายย้อนหลัง
class ReportController extends GetxController {
  ReportController({
    required GetSalesSummaryUseCase getSummary,
    required GetTopItemsUseCase getTopItems,
    required GetSalesByDayUseCase getSalesByDay,
  }) : _getSummary = getSummary,
       _getTopItems = getTopItems,
       _getSalesByDay = getSalesByDay;

  final GetSalesSummaryUseCase _getSummary;
  final GetTopItemsUseCase _getTopItems;
  final GetSalesByDayUseCase _getSalesByDay;

  final Rx<SalesSummary> summary = SalesSummary.empty.obs;
  final RxList<TopItem> topItems = <TopItem>[].obs;
  final RxList<DailySales> dailySales = <DailySales>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final Rx<ReportRange> range = ReportRange.today.obs;

  late DateTime from;
  late DateTime to;

  @override
  void onInit() {
    super.onInit();
    selectRange(ReportRange.today);
  }

  String get fromLabel => Formatters.date(from);
  String get toLabel => Formatters.date(to);

  void selectRange(ReportRange value) {
    final now = AppClock.now();
    range.value = value;

    switch (value) {
      case ReportRange.today:
        from = DateTime(now.year, now.month, now.day);
        to = from;
      case ReportRange.last7Days:
        to = DateTime(now.year, now.month, now.day);
        from = to.subtract(const Duration(days: 6));
      case ReportRange.thisMonth:
        from = DateTime(now.year, now.month);
        to = DateTime(now.year, now.month, now.day);
      case ReportRange.custom:
        break;
    }
    load();
  }

  void setCustomRange(DateTime start, DateTime end) {
    range.value = ReportRange.custom;
    from = start;
    to = end;
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final params = DateRangeParams(
      from: Formatters.isoDate(from),
      to: Formatters.isoDate(to),
      limit: 10,
    );

    final results = await Future.wait([
      _getSummary(params),
      _getTopItems(params),
      _getSalesByDay(params),
    ]);

    isLoading.value = false;

    results[0].fold(
      onSuccess: (data) => summary.value = data as SalesSummary,
      onFailure: (failure) => errorMessage.value = failure.message,
    );
    results[1].fold(
      onSuccess: (data) => topItems.assignAll(data as List<TopItem>),
      onFailure: (_) {},
    );
    results[2].fold(
      onSuccess: (data) => dailySales.assignAll(data as List<DailySales>),
      onFailure: (_) {},
    );
  }
}
