import '../../../../core/constants/app_constants.dart';

/// การชำระเงิน 1 ครั้ง (1 ออเดอร์อาจมีหลายครั้งได้ กรณีแยกจ่าย)
class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    this.received = 0,
    this.change = 0,
    this.reference,
    this.cashierName,
    this.createdAt,
  });

  final int id;
  final int orderId;
  final String method;
  final double amount;
  final double received;
  final double change;
  final String? reference;
  final String? cashierName;
  final String? createdAt;

  String get methodLabel => PaymentMethod.label(method);
}

/// สรุปยอดชำระของออเดอร์
class PaymentSummary {
  const PaymentSummary({
    required this.orderId,
    required this.total,
    required this.paid,
    required this.remaining,
    this.payments = const [],
  });

  final int orderId;
  final double total;
  final double paid;
  final double remaining;
  final List<Payment> payments;

  bool get isFullyPaid => remaining <= 0;
  bool get isPartiallyPaid => paid > 0 && remaining > 0;
}

/// ผลลัพธ์หลังกดชำระเงิน
class PaymentResult {
  const PaymentResult({
    required this.payment,
    required this.isFullyPaid,
    required this.remaining,
  });

  final Payment payment;
  final bool isFullyPaid;
  final double remaining;
}

/// ข้อมูลใบเสร็จ
class Receipt {
  const Receipt({
    required this.storeName,
    required this.currency,
    required this.vatRate,
    required this.serviceChargeRate,
    required this.payments,
    this.paidAt,
    this.changeTotal = 0,
  });

  final String storeName;
  final String currency;
  final double vatRate;
  final double serviceChargeRate;
  final List<Payment> payments;
  final String? paidAt;
  final double changeTotal;
}
