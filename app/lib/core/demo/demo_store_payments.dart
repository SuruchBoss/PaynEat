part of 'demo_store.dart';

// --------------------------------------------------------- payments -----
extension DemoStorePayments on DemoStore {
  double paidAmount(int orderId) => payments
      .where((row) => row['orderId'] == orderId)
      .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());

  Map<String, dynamic> paymentSummary(int orderId) {
    final order = findOrder(orderId);
    final paid = paidAmount(orderId);
    final total = (order['total'] as num).toDouble();
    return {
      'orderId': orderId,
      'total': total,
      'paid': paid,
      'remaining': max(0, total - paid),
      'payments': payments
          .where((row) => row['orderId'] == orderId)
          .toList(growable: false),
    };
  }

  Map<String, dynamic> pay({
    required int orderId,
    required String method,
    required double amount,
    double? received,
    String? reference,
    int? cashierId,
  }) {
    final order = findOrder(orderId);
    if (order['status'] == OrderStatus.paid) {
      throw const ApiException(
        message: 'ออเดอร์นี้ชำระเงินครบแล้ว',
        statusCode: 409,
      );
    }

    final total = (order['total'] as num).toDouble();
    final alreadyPaid = paidAmount(orderId);
    final remaining = total - alreadyPaid;

    if (amount > remaining + 0.001) {
      throw ApiException(
        message:
            'ยอดชำระเกินยอดคงเหลือ (คงเหลือ ${remaining.toStringAsFixed(2)} บาท)',
        statusCode: 400,
      );
    }

    final actualReceived = method == PaymentMethod.cash
        ? (received ?? amount)
        : amount;
    final payment = {
      'id': _nextId(),
      'orderId': orderId,
      'method': method,
      'amount': amount,
      'received': actualReceived,
      'change': method == PaymentMethod.cash
          ? max(0, actualReceived - amount)
          : 0.0,
      'reference': reference,
      'cashierId': cashierId,
      'cashierName': cashierId == null ? null : _findUser(cashierId)['name'],
      'createdAt': _now(),
    };
    payments.add(payment);

    final isFullyPaid = alreadyPaid + amount >= total - 0.001;
    if (isFullyPaid) {
      order['status'] = OrderStatus.paid;
      order['closedAt'] = _now();
      _freeTable(order);
    }

    return {
      'payment': payment,
      'order': order,
      'isFullyPaid': isFullyPaid,
      'remaining': max(0, total - (alreadyPaid + amount)),
    };
  }

  Map<String, dynamic> receipt(int orderId) {
    final order = findOrder(orderId);
    return {
      'store': {
        'name': settings['storeName'],
        'currency': settings['currency'],
        'vatRate': settings['vatRate'],
        'serviceChargeRate': settings['serviceChargeRate'],
      },
      'order': order,
      'payments': payments
          .where((row) => row['orderId'] == orderId)
          .toList(growable: false),
      'paidAt': order['closedAt'],
      'changeTotal': payments
          .where((row) => row['orderId'] == orderId)
          .fold<double>(
            0,
            (sum, row) => sum + (row['change'] as num).toDouble(),
          ),
    };
  }
}
