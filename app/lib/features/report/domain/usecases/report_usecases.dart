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
