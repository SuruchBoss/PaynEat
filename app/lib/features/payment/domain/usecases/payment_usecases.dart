import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../order/domain/entities/order.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class PayParams {
  const PayParams({
    required this.orderId,
    required this.method,
    this.amount,
    this.itemIds,
    this.received,
    this.reference,
  });

  final int orderId;
  final String method;

  /// ระบุอย่างใดอย่างหนึ่ง: [amount] (จ่ายเป็นจำนวนเงิน) หรือ [itemIds]
  /// (แยกบิลรายการอาหาร — เซิร์ฟเวอร์คำนวณยอดเองจากรายการที่เลือก)
  final double? amount;
  final List<int>? itemIds;
  final double? received;
  final String? reference;
}

/// รับชำระเงิน (รองรับจ่ายบางส่วน / แยกช่องทาง / แยกบิลรายการอาหาร)
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
    itemIds: params.itemIds,
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

class SplitPreviewParams {
  const SplitPreviewParams({required this.orderId, required this.itemIds});

  final int orderId;
  final List<int> itemIds;
}

/// ดูยอดที่ต้องจ่ายล่วงหน้าก่อนแยกบิลรายการอาหารจริง
class GetSplitPreviewUseCase
    implements UseCase<SplitPreview, SplitPreviewParams> {
  const GetSplitPreviewUseCase(this._repository);

  final PaymentRepository _repository;

  @override
  Future<Result<SplitPreview>> call(SplitPreviewParams params) =>
      _repository.getSplitPreview(params.orderId, params.itemIds);
}

class GetReceiptUseCase
    implements UseCase<({Receipt receipt, Order order}), int> {
  const GetReceiptUseCase(this._repository);

  final PaymentRepository _repository;

  @override
  Future<Result<({Receipt receipt, Order order})>> call(int params) =>
      _repository.getReceipt(params);
}
