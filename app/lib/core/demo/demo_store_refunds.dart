// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

part of 'demo_store.dart';

// --------------------------------------------------------- refunds -----
extension DemoStoreRefunds on DemoStore {
  List<Map<String, dynamic>> refundsByOrder(int orderId) =>
      refunds.where((row) => row['orderId'] == orderId).toList(growable: false);

  double _refundedTotalByPayment(int paymentId) => refunds
      .where((row) => row['paymentId'] == paymentId)
      .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());

  /// mirror ของ `planRefund` ใน payment.service.js (T11 #101, docs/DECISIONS.md #77 D7, #99): แบ่งยอดคืนเป็นเงินที่คืนจริง
  /// กับแต้มที่คืนให้ลูกค้าตามสัดส่วนที่ลูกค้าจ่ายมา ใช้ทั้งหน้าดูตัวอย่างและตอนคืนจริง ตัวเลขสองที่จึงตรงกันเสมอ
  ({
    int refunded,
    int pointsReturned,
    int pointsValueReturned,
    int refundable,
    RefundSplit split,
  })
  _planRefund(Map<String, dynamic> payment, double amount) {
    int cents(Object? baht) => (((baht as num?) ?? 0) * 100).round();
    final rows = refunds.where((row) => row['paymentId'] == payment['id']);
    final refunded = rows.fold<int>(
      0,
      (sum, row) => sum + cents(row['amount']),
    );
    final pointsReturned = rows.fold<int>(
      0,
      (sum, row) => sum + ((row['pointsReturned'] as int?) ?? 0),
    );
    final pointsValueReturned = rows.fold<int>(
      0,
      (sum, row) => sum + cents(row['pointsValue']),
    );
    final refundable = cents(payment['amount']) - refunded;
    final amountCents = cents(amount);
    if (amountCents > refundable) {
      throw ApiException(
        message: 'payment_error_refund_exceeds_refundable'.trParams({
          'amount': (refundable / 100).toStringAsFixed(2),
        }),
        statusCode: 400,
      );
    }
    final split = splitRefund(
      paymentAmount: cents(payment['amount']),
      pointsRedeemed: (payment['pointsRedeemed'] as int?) ?? 0,
      pointsRedeemedValue: cents(payment['pointsRedeemedValue']),
      refunded: refunded,
      pointsReturned: pointsReturned,
      pointsValueReturned: pointsValueReturned,
      amount: amountCents,
    );
    if (split == null) {
      throw ApiException(
        message: 'payment_error_refund_points_whole'.trParams({
          'amount': (refundable / 100).toStringAsFixed(2),
        }),
        statusCode: 400,
      );
    }
    return (
      refunded: refunded,
      pointsReturned: pointsReturned,
      pointsValueReturned: pointsValueReturned,
      refundable: refundable,
      split: split,
    );
  }

  Map<String, dynamic> _findPayment(int paymentId) => payments.firstWhere(
    (row) => row['id'] == paymentId,
    orElse: () => throw ApiException(
      message: 'payment_error_payment_not_found'.tr,
      statusCode: 404,
    ),
  );

  /// mirror ของ payment.service.js#refundPreview — ยอดเงินและแต้มที่จะคืนก่อนกดยืนยัน ไม่เขียนข้อมูล
  Map<String, dynamic> refundPreview({
    required int paymentId,
    required double amount,
  }) {
    final payment = _findPayment(paymentId);
    final plan = _planRefund(payment, amount);
    int cents(Object? baht) => (((baht as num?) ?? 0) * 100).round();
    final cashReceived =
        cents(payment['amount']) - cents(payment['pointsRedeemedValue']);
    return {
      'paymentId': paymentId,
      'amount': cents(amount) / 100,
      'cashAmount': plan.split.cashAmount / 100,
      'pointsReturned': plan.split.points,
      'pointsValue': plan.split.pointsValue / 100,
      'refundable': plan.refundable / 100,
      'cashRefundable':
          (cashReceived - (plan.refunded - plan.pointsValueReturned)) / 100,
      'pointsRefundable':
          ((payment['pointsRedeemed'] as int?) ?? 0) - plan.pointsReturned,
    };
  }

  /// คืนเงินหลังชำระเงินแล้ว (เต็มจำนวน/บางส่วน) — ผูกกับ payment โดยตรงเพราะออเดอร์
  /// เดียวอาจมีหลาย payment (แยกจ่าย) ไม่แก้ payment เดิมหรือสถานะออเดอร์ คืนบนบิลที่ยังเปิดได้
  /// ยอดคงเหลือเพิ่มขึ้นตามยอดที่คืนผ่าน [paidAmount] (DECISIONS #77 D1, #87)
  Map<String, dynamic> refundPayment({
    required int paymentId,
    required double amount,
    required String reason,
    required int refundedById,
  }) {
    final payment = _findPayment(paymentId);
    final split = _planRefund(payment, amount).split;

    // บิลขายเชื่อ: การคืนคือลดหนี้ ลดได้ไม่เกินยอดที่ยังค้าง (mirror ของ payment.service.js#refund)
    if (payment['method'] == PaymentMethod.credit) {
      final owed = creditRefundable(paymentId);
      if (amount > owed + 0.001) {
        throw ApiException(
          message: 'payment_error_credit_refund_exceeds_owed'.trParams({
            'amount': owed.toStringAsFixed(2),
          }),
          statusCode: 400,
        );
      }
    }

    // mirror ของ payment.service.js#refund — เงินสดที่คืนออกจากลิ้นชักของกะที่เปิดอยู่ตอนคืน จึงต้องมี
    // กะเปิดอยู่ (กฎเดียวกับตอนรับเงิน) คืนผ่านช่องทางอื่นไม่แตะลิ้นชักจึงไม่บังคับ — ดู DECISIONS #44
    final shift = _openShift;
    if (shift == null && payment['method'] == PaymentMethod.cash) {
      throw ApiException(
        message: 'payment_error_refund_shift_required'.tr,
        statusCode: 409,
      );
    }

    final previousCredited = _refundedTotalByPayment(paymentId);
    final refund = <String, dynamic>{
      'id': _nextId(),
      'paymentId': paymentId,
      'orderId': payment['orderId'],
      'shiftId': shift?['id'],
      'amount': amount,
      'cashAmount': split.cashAmount / 100,
      'pointsReturned': split.points,
      'pointsValue': split.pointsValue / 100,
      'reason': reason,
      'refundedBy': refundedById,
      'refundedByName': DemoNames.of(_findUser(refundedById)),
      'createdAt': _now(),
      'creditNoteId': null,
      'creditNoteNo': null,
    };
    refunds.add(refund);

    // ลดหนี้บิลขายเชื่อต้องมีเอกสารให้ลูกค้าเสมอ (ใบลดหนี้ DECISIONS #56)
    if (payment['method'] == PaymentMethod.credit) {
      _issueCreditNote(
        payment: payment,
        refund: refund,
        previousCredited: previousCredited,
        actorId: refundedById,
      );
      // ลดหนี้ส่วนที่เหลือจนยอดค้างเป็น 0 = ชำระครบ ได้แต้มจากยอดสุทธิ (DECISIONS #59)
      _syncCreditPoints(payment['orderId'] as int);
    }

    // mirror ของ payment.service.js#refund — ดู docs/tickets/08-audit-log.md
    final order = findOrder(payment['orderId'] as int);

    // แต้มส่วนที่คืนกลับเข้าบัญชีลูกค้าของบิล (T11 #101)
    final customerId = order['customerId'] as int?;
    if (split.points > 0 && customerId != null) {
      adjustCustomerPoints(customerId, split.points);
    }

    // คืน payment ที่แยกจ่ายตามรายการครบบนบิลที่ยังเปิด → รายการของ payment นั้นกลับเป็นยังไม่จ่าย (T06 #82)
    final isOpen =
        order['status'] != OrderStatus.paid &&
        order['status'] != OrderStatus.cancelled;
    if (isOpen &&
        previousCredited + amount >= (payment['amount'] as num) - 0.001) {
      for (final item
          in (order['items'] as List).cast<Map<String, dynamic>>()) {
        if (item['paidByPaymentId'] == paymentId) {
          item['isPaid'] = false;
          item['paidByPaymentId'] = null;
        }
      }
    }
    _logAudit(
      actorId: refundedById,
      action: 'payment.refund',
      summaryArgs: {'code': order['code'], 'amount': amount},
      entityType: 'refund',
      entityId: refund['id'] as int,
      summary: 'คืนเงิน ${_jsNumber(amount)} บาท ให้ออเดอร์ #${order['code']}',
      reason: reason,
      metadata: {
        'paymentId': paymentId,
        'orderId': payment['orderId'],
        'amount': amount,
        'cashAmount': split.cashAmount / 100,
        'pointsReturned': split.points,
      },
    );

    return refund;
  }
}
