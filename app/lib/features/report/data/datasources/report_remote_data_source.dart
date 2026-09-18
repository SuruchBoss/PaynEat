import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/report.dart';
import '../models/report_model.dart';

abstract class ReportRemoteDataSource {
  Future<DashboardData> getDashboard();
  Future<SalesSummary> getSummary({String? from, String? to});
  Future<List<TopItem>> getTopItems({String? from, String? to, int limit});
  Future<List<DailySales>> getSalesByDay({String? from, String? to});

  /// export รายงานเป็น CSV ดิบ (ดู docs/tickets/12-report-export.md)
  Future<String> exportSummaryCsv({String? from, String? to});
  Future<String> exportTopItemsCsv({String? from, String? to, int limit});
  Future<String> exportSalesByDayCsv({String? from, String? to});

  Future<ZReport> getZReportByShift(int shiftId);
  Future<ZReport> getZReportByDate(String? date);
  Future<String> exportZReportByShiftCsv(int shiftId);
  Future<String> exportZReportByDateCsv(String? date);
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  const ReportRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<DashboardData> getDashboard() async {
    final result = await _client.get(ApiEndpoints.dashboard);
    return ReportMapper.dashboardFromJson(result.asMap);
  }

  @override
  Future<SalesSummary> getSummary({String? from, String? to}) async {
    final result = await _client.get(
      ApiEndpoints.reportSummary,
      query: {'from': from, 'to': to},
    );
    return ReportMapper.summaryFromJson(result.asMap);
  }

  @override
  Future<List<TopItem>> getTopItems({
    String? from,
    String? to,
    int limit = 10,
  }) async {
    final result = await _client.get(
      ApiEndpoints.topItems,
      query: {'from': from, 'to': to, 'limit': limit},
    );
    return result.asList
        .map(ReportMapper.topItemFromJson)
        .toList(growable: false);
  }

  @override
  Future<List<DailySales>> getSalesByDay({String? from, String? to}) async {
    final result = await _client.get(
      ApiEndpoints.salesByDay,
      query: {'from': from, 'to': to},
    );
    return result.asList
        .map(ReportMapper.dailyFromJson)
        .toList(growable: false);
  }

  @override
  Future<String> exportSummaryCsv({String? from, String? to}) => _client
      .getText(ApiEndpoints.exportSummary, query: {'from': from, 'to': to});

  @override
  Future<String> exportTopItemsCsv({
    String? from,
    String? to,
    int limit = 10,
  }) => _client.getText(
    ApiEndpoints.exportTopItems,
    query: {'from': from, 'to': to, 'limit': limit},
  );

  @override
  Future<String> exportSalesByDayCsv({String? from, String? to}) => _client
      .getText(ApiEndpoints.exportSalesByDay, query: {'from': from, 'to': to});

  @override
  Future<ZReport> getZReportByShift(int shiftId) async {
    final result = await _client.get(ApiEndpoints.zReportByShift(shiftId));
    return ReportMapper.zReportFromJson(result.asMap);
  }

  @override
  Future<ZReport> getZReportByDate(String? date) async {
    final result = await _client.get(
      ApiEndpoints.zReportByDate,
      query: {'date': date},
    );
    return ReportMapper.zReportFromJson(result.asMap);
  }

  @override
  Future<String> exportZReportByShiftCsv(int shiftId) =>
      _client.getText(ApiEndpoints.zReportByShiftExport(shiftId));

  @override
  Future<String> exportZReportByDateCsv(String? date) =>
      _client.getText(ApiEndpoints.zReportByDateExport, query: {'date': date});
}
