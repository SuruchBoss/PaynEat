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

  /// ตรวจว่ารายการที่เลือกแยกบิลถูกต้อง — อยู่ในออเดอร์จริง ยังไม่ถูกยกเลิก และยังไม่ถูกจ่ายไปก่อนหน้า
  void _assertItemsSelectable(Map<String, dynamic> order, List<int> itemIds) {
    final items = (order['items'] as List).cast<Map<String, dynamic>>();
    for (final id in itemIds) {
      if (!items.any((item) => item['id'] == id)) {
        throw const ApiException(
          message: 'มีรายการที่ไม่ได้อยู่ในออเดอร์นี้',
          statusCode: 400,
        );
      }
    }
    for (final item in items.where((item) => itemIds.contains(item['id']))) {
      if (item['isPaid'] == true) {
        throw ApiException(
          message: '"${item['name']}" ถูกจ่ายไปแล้ว',
          statusCode: 409,
        );
      }
      if (item['status'] == OrderItemStatus.cancelled) {
        throw ApiException(
          message: '"${item['name']}" ถูกยกเลิกไปแล้ว เลือกจ่ายไม่ได้',
          statusCode: 400,
        );
      }
    }
  }

  /// คำนวณส่วนแบ่งบิลของรายการที่เลือก — คิดสัดส่วนตาม subtotal เทียบกับทั้งบิล
  /// แล้วเฉลี่ยส่วนลด/Service Charge/VAT ตามสัดส่วนนั้น (ดูสูตรเดียวกันที่
  /// backend/src/modules/orders/order.calculator.js#calculateItemsShare)
  Map<String, dynamic> _itemsShare(
    Map<String, dynamic> order,
    List<int> itemIds,
  ) {
    final items = (order['items'] as List).cast<Map<String, dynamic>>();
    final active = items
        .where((item) => item['status'] != OrderItemStatus.cancelled)
        .toList();
    final unpaidActive = active
        .where((item) => item['isPaid'] != true)
        .toList();
    final selected = active.where((item) => itemIds.contains(item['id']));

    final fullSubtotal = active.fold<double>(
      0,
      (sum, item) => sum + (item['lineTotal'] as num).toDouble(),
    );
    final selectedSubtotal = selected.fold<double>(
      0,
      (sum, item) => sum + (item['lineTotal'] as num).toDouble(),
    );
    final share = fullSubtotal > 0 ? selectedSubtotal / fullSubtotal : 0.0;

    final discountAmount = _roundMoney(
      (order['discountAmount'] as num).toDouble() * share,
    );
    final serviceCharge = _roundMoney(
      (order['serviceCharge'] as num).toDouble() * share,
    );
    final vat = _roundMoney((order['vat'] as num).toDouble() * share);
    final total = selectedSubtotal - discountAmount + serviceCharge + vat;

    final isLastBatch =
        unpaidActive.isNotEmpty &&
        unpaidActive.every((item) => itemIds.contains(item['id']));

    return {
      'subtotal': selectedSubtotal,
      'discountAmount': discountAmount,
      'serviceCharge': serviceCharge,
      'vat': vat,
      'total': total,
      'isLastBatch': isLastBatch,
    };
  }

  static double _roundMoney(double value) => (value * 100).round() / 100;

  /// ดูยอดที่ต้องจ่ายล่วงหน้าก่อนแยกบิล โดยยังไม่ตัดจ่ายจริง
  Map<String, dynamic> splitPreview(int orderId, List<int> itemIds) {
    final order = findOrder(orderId);
    if (order['status'] == OrderStatus.cancelled) {
      throw const ApiException(
        message: 'ออเดอร์นี้ถูกยกเลิกแล้ว',
        statusCode: 409,
      );
    }
    if (order['status'] == OrderStatus.paid) {
      throw const ApiException(
        message: 'ออเดอร์นี้ชำระเงินครบแล้ว',
        statusCode: 409,
      );
    }
    _assertItemsSelectable(order, itemIds);

    final total = (order['total'] as num).toDouble();
    final alreadyPaid = paidAmount(orderId);
    final remaining = max<double>(0, total - alreadyPaid);
    final share = _itemsShare(order, itemIds);
    final amount = (share['isLastBatch'] as bool)
        ? remaining
        : min(share['total'] as double, remaining);

    return {
      'orderId': orderId,
      'itemIds': itemIds,
      'subtotal': share['subtotal'],
      'discountAmount': share['discountAmount'],
      'serviceCharge': share['serviceCharge'],
      'vat': share['vat'],
      'total': amount,
      'remaining': remaining,
      'isLastBatch': share['isLastBatch'],
    };
  }

  Map<String, dynamic> pay({
    required int orderId,
    required String method,
    double? amount,
    List<int>? itemIds,
    double? received,
    String? reference,
    int? cashierId,
  }) {
    final shift = _openShift;
    if (shift == null) {
      throw const ApiException(
        message: 'ต้องเปิดกะก่อนจึงจะรับชำระเงินได้',
        statusCode: 409,
      );
    }

    final order = findOrder(orderId);
    if (order['status'] == OrderStatus.cancelled) {
      throw const ApiException(
        message: 'ออเดอร์นี้ถูกยกเลิกแล้ว',
        statusCode: 409,
      );
    }
    if (order['status'] == OrderStatus.paid) {
      throw const ApiException(
        message: 'ออเดอร์นี้ชำระเงินครบแล้ว',
        statusCode: 409,
      );
    }

    final total = (order['total'] as num).toDouble();
    final alreadyPaid = paidAmount(orderId);
    final remaining = total - alreadyPaid;

    double resolvedAmount;
    if (itemIds != null && itemIds.isNotEmpty) {
      _assertItemsSelectable(order, itemIds);
      final share = _itemsShare(order, itemIds);
      resolvedAmount = (share['isLastBatch'] as bool)
          ? remaining
          : min(share['total'] as double, remaining);
    } else {
      resolvedAmount = amount ?? 0;
    }

    if (resolvedAmount > remaining + 0.001) {
      throw ApiException(
        message:
            'ยอดชำระเกินยอดคงเหลือ (คงเหลือ ${remaining.toStringAsFixed(2)} บาท)',
        statusCode: 400,
      );
    }

    final actualReceived = method == PaymentMethod.cash
        ? (received ?? resolvedAmount)
        : resolvedAmount;
    if (method == PaymentMethod.cash &&
        actualReceived + 0.001 < resolvedAmount) {
      throw const ApiException(
        message: 'เงินที่รับมาต้องไม่น้อยกว่ายอดที่ชำระ',
        statusCode: 400,
      );
    }

    final payment = {
      'id': _nextId(),
      'orderId': orderId,
      'shiftId': shift['id'],
      'method': method,
      'amount': resolvedAmount,
      'received': actualReceived,
      'change': method == PaymentMethod.cash
          ? max(0, actualReceived - resolvedAmount)
          : 0.0,
      'reference': reference,
      'cashierId': cashierId,
      'cashierName': cashierId == null ? null : _findUser(cashierId)['name'],
      'createdAt': _now(),
    };
    payments.add(payment);

    if (itemIds != null && itemIds.isNotEmpty) {
      for (final item
          in (order['items'] as List).cast<Map<String, dynamic>>()) {
        if (itemIds.contains(item['id'])) item['isPaid'] = true;
      }
    }

    final isFullyPaid = alreadyPaid + resolvedAmount >= total - 0.001;
    if (isFullyPaid) {
      order['status'] = OrderStatus.paid;
      order['closedAt'] = _now();
      _freeTable(order);
    }

    return {
      'payment': payment,
      'order': order,
      'isFullyPaid': isFullyPaid,
      'remaining': max(0, total - (alreadyPaid + resolvedAmount)),
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
