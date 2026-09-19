import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../order/domain/entities/order.dart';
import '../../../order/domain/entities/order_item_payload.dart';
import '../repositories/self_order_repository.dart';

class AddSelfOrderItemsParams {
  const AddSelfOrderItemsParams({required this.qrToken, required this.items});

  final String qrToken;
  final List<OrderItemPayload> items;
}

class AddSelfOrderItemsUseCase
    implements UseCase<Order, AddSelfOrderItemsParams> {
  const AddSelfOrderItemsUseCase(this._repository);

  final SelfOrderRepository _repository;

  @override
  Future<Result<Order>> call(AddSelfOrderItemsParams params) =>
      _repository.addItems(params.qrToken, params.items);
}
