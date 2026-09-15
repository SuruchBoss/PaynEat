part of 'demo_store.dart';

// --------------------------------------------------------- refunds -----
extension DemoStoreRefunds on DemoStore {
  List<Map<String, dynamic>> refundsByOrder(int orderId) =>
      refunds.where((row) => row['orderId'] == orderId).toList(growable: false);

  double _refundedTotalByPayment(int paymentId) => refunds
      .where((row) => row['paymentId'] == paymentId)
      .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());

  /// คืนเงินหลังชำระเงินแล้ว (เต็มจำนวน/บางส่วน) — ผูกกับ payment โดยตรงเพราะออเดอร์
  /// เดียวอาจมีหลาย payment (แยกจ่าย) ไม่แก้ payment เดิมหรือสถานะออเดอร์
  Map<String, dynamic> refundPayment({
    required int paymentId,
    required double amount,
    required String reason,
    required int refundedById,
  }) {
    final payment = payments.firstWhere(
      (row) => row['id'] == paymentId,
      orElse: () => throw ApiException(
        message: 'payment_error_payment_not_found'.tr,
        statusCode: 404,
      ),
    );

    final refundable =
        (payment['amount'] as num).toDouble() -
        _refundedTotalByPayment(paymentId);
    if (amount > refundable + 0.001) {
      throw ApiException(
        message: 'payment_error_refund_exceeds_refundable'.trParams({
          'amount': refundable.toStringAsFixed(2),
        }),
        statusCode: 400,
      );
    }

    final refund = {
      'id': _nextId(),
      'paymentId': paymentId,
      'orderId': payment['orderId'],
      'amount': amount,
      'reason': reason,
      'refundedBy': refundedById,
      'refundedByName': _findUser(refundedById)['name'],
      'createdAt': _now(),
    };
    refunds.add(refund);
    return refund;
  }
}
