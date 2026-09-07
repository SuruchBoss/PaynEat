import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/report.dart';
import '../models/report_model.dart';

abstract class ReportRemoteDataSource {
  Future<DashboardData> getDashboard();
  Future<SalesSummary> getSummary({String? from, String? to});
  Future<List<TopItem>> getTopItems({String? from, String? to, int limit});
  Future<List<DailySales>> getSalesByDay({String? from, String? to});
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
  Future<List<TopItem>> getTopItems({String? from, String? to, int limit = 10}) async {
    final result = await _client.get(
      ApiEndpoints.topItems,
      query: {'from': from, 'to': to, 'limit': limit},
    );
    return result.asList.map(ReportMapper.topItemFromJson).toList(growable: false);
  }

  @override
  Future<List<DailySales>> getSalesByDay({String? from, String? to}) async {
    final result = await _client.get(
      ApiEndpoints.salesByDay,
      query: {'from': from, 'to': to},
    );
    return result.asList.map(ReportMapper.dailyFromJson).toList(growable: false);
  }
}
