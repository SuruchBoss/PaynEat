part of 'demo_data_sources.dart';

class DemoPaymentDataSource implements PaymentRemoteDataSource {
  DemoPaymentDataSource(this._store, this._auth);

  final DemoStore _store;
  final DemoAuthDataSource _auth;

  @override
  Future<({PaymentResult result, OrderModel order})> pay({
    required int orderId,
    required String method,
    double? amount,
    List<int>? itemIds,
    double? received,
    String? reference,
    int? pointsToRedeem,
  }) => _delayed(() {
    final data = _store.pay(
      orderId: orderId,
      method: method,
      amount: amount,
      itemIds: itemIds,
      received: received,
      reference: reference,
      cashierId: _auth.currentUserId,
      pointsToRedeem: pointsToRedeem ?? 0,
    );
    return (
      result: PaymentResult(
        payment: PaymentModel.fromJson(data['payment'] as Map<String, dynamic>),
        isFullyPaid: data['isFullyPaid'] as bool,
        remaining: (data['remaining'] as num).toDouble(),
      ),
      order: OrderModel.fromJson(data['order'] as Map<String, dynamic>),
    );
  });

  @override
  Future<PaymentSummaryModel> getSummary(int orderId) => _delayed(
    () => PaymentSummaryModel.fromJson(_store.paymentSummary(orderId)),
  );

  @override
  Future<SplitPreviewModel> getSplitPreview(int orderId, List<int> itemIds) =>
      _delayed(
        () => SplitPreviewModel.fromJson(_store.splitPreview(orderId, itemIds)),
      );

  @override
  Future<({Receipt receipt, OrderModel order})> getReceipt(int orderId) =>
      _delayed(() {
        final data = _store.receipt(orderId);
        final store = data['store'] as Map<String, dynamic>;
        return (
          receipt: Receipt(
            storeName: store['name'] as String,
            currency: store['currency'] as String,
            vatRate: (store['vatRate'] as num).toDouble(),
            serviceChargeRate: (store['serviceChargeRate'] as num).toDouble(),
            paidAt: data['paidAt'] as String?,
            changeTotal: (data['changeTotal'] as num).toDouble(),
            payments: (data['payments'] as List)
                .cast<Map<String, dynamic>>()
                .map(PaymentModel.fromJson)
                .toList(growable: false),
            refunds: (data['refunds'] as List)
                .cast<Map<String, dynamic>>()
                .map(RefundModel.fromJson)
                .toList(growable: false),
            refundedTotal: (data['refundedTotal'] as num).toDouble(),
          ),
          order: OrderModel.fromJson(data['order'] as Map<String, dynamic>),
        );
      });

  @override
  Future<PromptPayQrModel> getPromptPayQr(double? amount) => _delayed(() {
    final promptPayId = _store.settings['promptPayId'] as String?;
    if (promptPayId == null || promptPayId.isEmpty) {
      throw ApiException(
        message: 'settings_promptpay_not_configured_error'.tr,
        statusCode: 400,
      );
    }
    return PromptPayQrModel(
      payload: buildPromptPayPayload(promptPayId: promptPayId, amount: amount),
      promptPayId: promptPayId,
      amount: amount,
    );
  });

  @override
  Future<RefundModel> refund({
    required int paymentId,
    required double amount,
    required String reason,
  }) => _delayed(
    () => RefundModel.fromJson(
      _store.refundPayment(
        paymentId: paymentId,
        amount: amount,
        reason: reason,
        refundedById: _auth.currentUserId ?? 0,
      ),
    ),
  );
}
