// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/report.dart';
import '../repositories/report_repository.dart';

class GetDashboardUseCase implements NoParamsUseCase<DashboardData> {
  const GetDashboardUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<DashboardData>> call() => _repository.getDashboard();
}

class DateRangeParams {
  const DateRangeParams({this.from, this.to, this.limit = 10});

  final String? from;
  final String? to;
  final int limit;
}

class GetSalesSummaryUseCase implements UseCase<SalesSummary, DateRangeParams> {
  const GetSalesSummaryUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<SalesSummary>> call(DateRangeParams params) =>
      _repository.getSummary(from: params.from, to: params.to);
}

class GetTopItemsUseCase implements UseCase<List<TopItem>, DateRangeParams> {
  const GetTopItemsUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<List<TopItem>>> call(DateRangeParams params) => _repository
      .getTopItems(from: params.from, to: params.to, limit: params.limit);
}

class GetSalesByDayUseCase
    implements UseCase<List<DailySales>, DateRangeParams> {
  const GetSalesByDayUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<List<DailySales>>> call(DateRangeParams params) =>
      _repository.getSalesByDay(from: params.from, to: params.to);
}

/// export รายงานเป็น CSV ตามช่วงวันที่เดียวกับหน้าจอ (ดู docs/tickets/12-report-export.md)
class ExportSummaryCsvUseCase implements UseCase<String, DateRangeParams> {
  const ExportSummaryCsvUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<String>> call(DateRangeParams params) =>
      _repository.exportSummaryCsv(from: params.from, to: params.to);
}

class ExportTopItemsCsvUseCase implements UseCase<String, DateRangeParams> {
  const ExportTopItemsCsvUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<String>> call(DateRangeParams params) => _repository
      .exportTopItemsCsv(from: params.from, to: params.to, limit: params.limit);
}

class ExportSalesByDayCsvUseCase implements UseCase<String, DateRangeParams> {
  const ExportSalesByDayCsvUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<String>> call(DateRangeParams params) =>
      _repository.exportSalesByDayCsv(from: params.from, to: params.to);
}

/// Z-report ต่อกะ (มีกระทบยอดเงินสด) หรือต่อวัน (รวมทุกกะ) — ดู docs/tickets/12-report-export.md
class GetZReportByShiftUseCase implements UseCase<ZReport, int> {
  const GetZReportByShiftUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<ZReport>> call(int shiftId) =>
      _repository.getZReportByShift(shiftId);
}

class GetZReportByDateUseCase implements UseCase<ZReport, String?> {
  const GetZReportByDateUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<ZReport>> call(String? date) =>
      _repository.getZReportByDate(date);
}

class ExportZReportByShiftCsvUseCase implements UseCase<String, int> {
  const ExportZReportByShiftCsvUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<String>> call(int shiftId) =>
      _repository.exportZReportByShiftCsv(shiftId);
}

class ExportZReportByDateCsvUseCase implements UseCase<String, String?> {
  const ExportZReportByDateCsvUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<String>> call(String? date) =>
      _repository.exportZReportByDateCsv(date);
}
