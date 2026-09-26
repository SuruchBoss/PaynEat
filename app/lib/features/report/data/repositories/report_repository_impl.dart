// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_data_source.dart';

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(this._remote);

  final ReportRemoteDataSource _remote;

  @override
  Future<Result<DashboardData>> getDashboard() =>
      guard(() => _remote.getDashboard());

  @override
  Future<Result<SalesSummary>> getSummary({String? from, String? to}) =>
      guard(() => _remote.getSummary(from: from, to: to));

  @override
  Future<Result<List<TopItem>>> getTopItems({
    String? from,
    String? to,
    int limit = 10,
  }) => guard(() => _remote.getTopItems(from: from, to: to, limit: limit));

  @override
  Future<Result<List<DailySales>>> getSalesByDay({String? from, String? to}) =>
      guard(() => _remote.getSalesByDay(from: from, to: to));

  @override
  Future<Result<String>> exportSummaryCsv({String? from, String? to}) =>
      guard(() => _remote.exportSummaryCsv(from: from, to: to));

  @override
  Future<Result<String>> exportTopItemsCsv({
    String? from,
    String? to,
    int limit = 10,
  }) =>
      guard(() => _remote.exportTopItemsCsv(from: from, to: to, limit: limit));

  @override
  Future<Result<String>> exportSalesByDayCsv({String? from, String? to}) =>
      guard(() => _remote.exportSalesByDayCsv(from: from, to: to));

  @override
  Future<Result<ZReport>> getZReportByShift(int shiftId) =>
      guard(() => _remote.getZReportByShift(shiftId));

  @override
  Future<Result<ZReport>> getZReportByDate(String? date) =>
      guard(() => _remote.getZReportByDate(date));

  @override
  Future<Result<String>> exportZReportByShiftCsv(int shiftId) =>
      guard(() => _remote.exportZReportByShiftCsv(shiftId));

  @override
  Future<Result<String>> exportZReportByDateCsv(String? date) =>
      guard(() => _remote.exportZReportByDateCsv(date));
}
