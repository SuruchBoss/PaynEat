import '../../../../core/usecases/result.dart';
import '../entities/report.dart';

abstract class ReportRepository {
  Future<Result<DashboardData>> getDashboard();
  Future<Result<SalesSummary>> getSummary({String? from, String? to});
  Future<Result<List<TopItem>>> getTopItems({String? from, String? to, int limit});
  Future<Result<List<DailySales>>> getSalesByDay({String? from, String? to});
}
