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
}
