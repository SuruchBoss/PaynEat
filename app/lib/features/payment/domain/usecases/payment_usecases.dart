import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../order/domain/entities/order.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class PayParams {
  const PayParams({
    required this.orderId,
    required this.method,
    required this.amount,
    this.received,
    this.reference,
  });

  final int orderId;
  final String method;
  final double amount;
  final double? received;
  final String? reference;
}

/// รับชำระเงิน (รองรับจ่ายบางส่วน / แยกช่องทาง)
class PayOrderUseCase
    implements UseCase<({PaymentResult result, Order order}), PayParams> {
  const PayOrderUseCase(this._repository);

  final PaymentRepository _repository;

  @override
  Future<Result<({PaymentResult result, Order order})>> call(
    PayParams params,
  ) => _repository.pay(
    orderId: params.orderId,
    method: params.method,
    amount: params.amount,
    received: params.received,
    reference: params.reference,
  );
}

class GetPaymentSummaryUseCase implements UseCase<PaymentSummary, int> {
  const GetPaymentSummaryUseCase(this._repository);

  final PaymentRepository _repository;

  @override
  Future<Result<PaymentSummary>> call(int params) =>
      _repository.getSummary(params);
}

class GetReceiptUseCase
    implements UseCase<({Receipt receipt, Order order}), int> {
  const GetReceiptUseCase(this._repository);

  final PaymentRepository _repository;

  @override
  Future<Result<({Receipt receipt, Order order})>> call(int params) =>
      _repository.getReceipt(params);
}
