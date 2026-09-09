import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../../order/domain/entities/order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl(this._remote);

  final PaymentRemoteDataSource _remote;

  @override
  Future<Result<({PaymentResult result, Order order})>> pay({
    required int orderId,
    required String method,
    double? amount,
    List<int>? itemIds,
    double? received,
    String? reference,
  }) => guard(() async {
    final response = await _remote.pay(
      orderId: orderId,
      method: method,
      amount: amount,
      itemIds: itemIds,
      received: received,
      reference: reference,
    );
    return (result: response.result, order: response.order as Order);
  });

  @override
  Future<Result<PaymentSummary>> getSummary(int orderId) =>
      guard(() async => await _remote.getSummary(orderId));

  @override
  Future<Result<SplitPreview>> getSplitPreview(
    int orderId,
    List<int> itemIds,
  ) => guard(() async => await _remote.getSplitPreview(orderId, itemIds));

  @override
  Future<Result<({Receipt receipt, Order order})>> getReceipt(int orderId) =>
      guard(() async {
        final response = await _remote.getReceipt(orderId);
        return (receipt: response.receipt, order: response.order as Order);
      });

  @override
  Future<Result<Refund>> refund({
    required int paymentId,
    required double amount,
    required String reason,
  }) => guard(
    () async => await _remote.refund(
      paymentId: paymentId,
      amount: amount,
      reason: reason,
    ),
  );
}
