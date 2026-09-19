import '../../../../core/usecases/result.dart';
import '../entities/report.dart';

abstract class ReportRepository {
  Future<Result<DashboardData>> getDashboard();
  Future<Result<SalesSummary>> getSummary({String? from, String? to});
  Future<Result<List<TopItem>>> getTopItems({
    String? from,
    String? to,
    int limit,
  });
  Future<Result<List<DailySales>>> getSalesByDay({String? from, String? to});

  Future<Result<String>> exportSummaryCsv({String? from, String? to});
  Future<Result<String>> exportTopItemsCsv({
    String? from,
    String? to,
    int limit,
  });
  Future<Result<String>> exportSalesByDayCsv({String? from, String? to});

  Future<Result<ZReport>> getZReportByShift(int shiftId);
  Future<Result<ZReport>> getZReportByDate(String? date);
  Future<Result<String>> exportZReportByShiftCsv(int shiftId);
  Future<Result<String>> exportZReportByDateCsv(String? date);
}
