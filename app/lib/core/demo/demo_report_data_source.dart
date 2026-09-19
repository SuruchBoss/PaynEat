part of 'demo_data_sources.dart';

class DemoReportDataSource implements ReportRemoteDataSource {
  const DemoReportDataSource(this._store);

  final DemoStore _store;

  @override
  Future<DashboardData> getDashboard() =>
      _delayed(() => ReportMapper.dashboardFromJson(_store.dashboard()));

  @override
  Future<SalesSummary> getSummary({String? from, String? to}) => _delayed(
    () => ReportMapper.summaryFromJson(_store.salesSummary(from: from, to: to)),
  );

  @override
  Future<List<TopItem>> getTopItems({
    String? from,
    String? to,
    int limit = 10,
  }) => _delayed(
    () => _store
        .topItems(from: from, to: to, limit: limit)
        .map(ReportMapper.topItemFromJson)
        .toList(growable: false),
  );

  @override
  Future<List<DailySales>> getSalesByDay({String? from, String? to}) =>
      _delayed(
        () => _store
            .salesByDay(from: from, to: to)
            .map(ReportMapper.dailyFromJson)
            .toList(growable: false),
      );

  @override
  Future<String> exportSummaryCsv({String? from, String? to}) =>
      _delayed(() => _store.exportSummaryCsv(from: from, to: to));

  @override
  Future<String> exportTopItemsCsv({
    String? from,
    String? to,
    int limit = 10,
  }) => _delayed(
    () => _store.exportTopItemsCsv(from: from, to: to, limit: limit),
  );

  @override
  Future<String> exportSalesByDayCsv({String? from, String? to}) =>
      _delayed(() => _store.exportSalesByDayCsv(from: from, to: to));

  @override
  Future<ZReport> getZReportByShift(int shiftId) => _delayed(
    () => ReportMapper.zReportFromJson(_store.zReportByShift(shiftId)),
  );

  @override
  Future<ZReport> getZReportByDate(String? date) =>
      _delayed(() => ReportMapper.zReportFromJson(_store.zReportByDate(date)));

  @override
  Future<String> exportZReportByShiftCsv(int shiftId) =>
      _delayed(() => _store.exportZReportByShiftCsv(shiftId));

  @override
  Future<String> exportZReportByDateCsv(String? date) =>
      _delayed(() => _store.exportZReportByDateCsv(date));
}
