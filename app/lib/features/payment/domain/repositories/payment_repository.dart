import '../../../../core/usecases/result.dart';
import '../../../order/domain/entities/order.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<Result<({PaymentResult result, Order order})>> pay({
    required int orderId,
    required String method,
    required double amount,
    double? received,
    String? reference,
  });

  Future<Result<PaymentSummary>> getSummary(int orderId);

  Future<Result<({Receipt receipt, Order order})>> getReceipt(int orderId);
}
