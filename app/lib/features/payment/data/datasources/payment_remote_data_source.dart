import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../order/data/models/order_model.dart';
import '../../domain/entities/payment.dart';
import '../models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<({PaymentResult result, OrderModel order})> pay({
    required int orderId,
    required String method,
    required double amount,
    double? received,
    String? reference,
  });
  Future<PaymentSummaryModel> getSummary(int orderId);
  Future<({Receipt receipt, OrderModel order})> getReceipt(int orderId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  const PaymentRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<({PaymentResult result, OrderModel order})> pay({
    required int orderId,
    required String method,
    required double amount,
    double? received,
    String? reference,
  }) async {
    final response = await _client.post(
      ApiEndpoints.payments,
      body: {
        'orderId': orderId,
        'method': method,
        'amount': amount,
        if (received != null) 'received': received,
        if (reference != null && reference.isNotEmpty) 'reference': reference,
      },
    );

    final data = response.asMap;
    return (
      result: PaymentResult(
        payment: PaymentModel.fromJson(data['payment'] as Map<String, dynamic>),
        isFullyPaid: data['isFullyPaid'] as bool? ?? false,
        remaining: (data['remaining'] as num?)?.toDouble() ?? 0,
      ),
      order: OrderModel.fromJson(data['order'] as Map<String, dynamic>),
    );
  }

  @override
  Future<PaymentSummaryModel> getSummary(int orderId) async {
    final response = await _client.get(ApiEndpoints.paymentSummary(orderId));
    return PaymentSummaryModel.fromJson(response.asMap);
  }

  @override
  Future<({Receipt receipt, OrderModel order})> getReceipt(int orderId) async {
    final response = await _client.get(ApiEndpoints.receipt(orderId));
    final data = response.asMap;
    final store = data['store'] as Map<String, dynamic>? ?? const {};

    return (
      receipt: Receipt(
        storeName: store['name'] as String? ?? '',
        currency: store['currency'] as String? ?? 'THB',
        vatRate: (store['vatRate'] as num?)?.toDouble() ?? 0,
        serviceChargeRate: (store['serviceChargeRate'] as num?)?.toDouble() ?? 0,
        paidAt: data['paidAt'] as String?,
        changeTotal: (data['changeTotal'] as num?)?.toDouble() ?? 0,
        payments: (data['payments'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PaymentModel.fromJson)
            .toList(growable: false),
      ),
      order: OrderModel.fromJson(data['order'] as Map<String, dynamic>),
    );
  }
}
