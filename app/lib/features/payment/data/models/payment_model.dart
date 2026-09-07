import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.orderId,
    required super.method,
    required super.amount,
    super.received,
    super.change,
    super.reference,
    super.cashierName,
    super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    orderId: (json['orderId'] as num?)?.toInt() ?? 0,
    method: json['method'] as String? ?? 'cash',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    received: (json['received'] as num?)?.toDouble() ?? 0,
    change: (json['change'] as num?)?.toDouble() ?? 0,
    reference: json['reference'] as String?,
    cashierName: json['cashierName'] as String?,
    createdAt: json['createdAt'] as String?,
  );
}

class PaymentSummaryModel extends PaymentSummary {
  const PaymentSummaryModel({
    required super.orderId,
    required super.total,
    required super.paid,
    required super.remaining,
    super.payments,
  });

  factory PaymentSummaryModel.fromJson(Map<String, dynamic> json) =>
      PaymentSummaryModel(
        orderId: (json['orderId'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        paid: (json['paid'] as num?)?.toDouble() ?? 0,
        remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
        payments: (json['payments'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PaymentModel.fromJson)
            .toList(growable: false),
      );
}
