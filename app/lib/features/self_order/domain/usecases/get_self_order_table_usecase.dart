import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../order/domain/entities/order.dart';
import '../entities/self_order_table.dart';
import '../repositories/self_order_repository.dart';

class GetSelfOrderTableUseCase
    implements UseCase<({SelfOrderTable table, Order? order}), String> {
  const GetSelfOrderTableUseCase(this._repository);

  final SelfOrderRepository _repository;

  @override
  Future<Result<({SelfOrderTable table, Order? order})>> call(String qrToken) =>
      _repository.getTable(qrToken);
}
