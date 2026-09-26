// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:get/get.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/csv_download/csv_download.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/report.dart';
import '../../domain/usecases/report_usecases.dart';
import '../../../../core/utils/app_clock.dart';

/// ช่วงเวลาที่เลือกดูรายงาน
enum ReportRange { today, last7Days, thisMonth, custom }

/// รูปแบบ CSV ที่ export ได้จากหน้ารายงาน (ดู docs/tickets/12-report-export.md)
enum ReportExportKind { summary, topItems, salesByDay }

/// รายงานยอดขายย้อนหลัง
class ReportController extends GetxController {
  ReportController({
    required GetSalesSummaryUseCase getSummary,
    required GetTopItemsUseCase getTopItems,
    required GetSalesByDayUseCase getSalesByDay,
    required ExportSummaryCsvUseCase exportSummaryCsv,
    required ExportTopItemsCsvUseCase exportTopItemsCsv,
    required ExportSalesByDayCsvUseCase exportSalesByDayCsv,
  }) : _getSummary = getSummary,
       _getTopItems = getTopItems,
       _getSalesByDay = getSalesByDay,
       _exportSummaryCsv = exportSummaryCsv,
       _exportTopItemsCsv = exportTopItemsCsv,
       _exportSalesByDayCsv = exportSalesByDayCsv;

  final GetSalesSummaryUseCase _getSummary;
  final GetTopItemsUseCase _getTopItems;
  final GetSalesByDayUseCase _getSalesByDay;
  final ExportSummaryCsvUseCase _exportSummaryCsv;
  final ExportTopItemsCsvUseCase _exportTopItemsCsv;
  final ExportSalesByDayCsvUseCase _exportSalesByDayCsv;

  final Rx<SalesSummary> summary = SalesSummary.empty.obs;
  final RxList<TopItem> topItems = <TopItem>[].obs;
  final RxList<DailySales> dailySales = <DailySales>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isExporting = false.obs;
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

  /// export รายงานเป็น CSV ตามช่วงวันที่ที่กำลังดูอยู่ (ดู
  /// docs/tickets/12-report-export.md) — รองรับเฉพาะเว็บ (ดู core/utils/csv_download)
  Future<void> exportCsv(ReportExportKind kind) async {
    if (!isCsvDownloadSupported) {
      AppDialogs.error('report_export_unsupported_platform'.tr);
      return;
    }

    final params = DateRangeParams(
      from: Formatters.isoDate(from),
      to: Formatters.isoDate(to),
      limit: 10,
    );

    isExporting.value = true;
    final result = switch (kind) {
      ReportExportKind.summary => await _exportSummaryCsv(params),
      ReportExportKind.topItems => await _exportTopItemsCsv(params),
      ReportExportKind.salesByDay => await _exportSalesByDayCsv(params),
    };
    isExporting.value = false;

    result.fold(
      onSuccess: (csv) => downloadCsv(_exportFileName(kind), csv),
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  String _exportFileName(ReportExportKind kind) {
    final suffix = switch (kind) {
      ReportExportKind.summary => 'summary',
      ReportExportKind.topItems => 'top-items',
      ReportExportKind.salesByDay => 'sales-by-day',
    };
    return 'report-$suffix-${Formatters.isoDate(from)}-${Formatters.isoDate(to)}.csv';
  }
}
