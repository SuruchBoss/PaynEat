part of 'demo_store.dart';

// ----------------------------------------------------------- shifts -----
extension DemoStoreShifts on DemoStore {
  Map<String, dynamic>? get _openShift {
    for (final shift in shifts.reversed) {
      if (shift['status'] == ShiftStatus.open) return shift;
    }
    return null;
  }

  Map<String, dynamic>? currentShift() => _openShift;

  List<Map<String, dynamic>> shiftHistory() =>
      shifts.reversed.toList(growable: false);

  Map<String, dynamic> openShift({
    required double openingCash,
    required int openedById,
  }) {
    if (_openShift != null) {
      throw ApiException(
        message: 'shift_error_already_open'.tr,
        statusCode: 409,
      );
    }
    final shift = {
      'id': _nextId(),
      'status': ShiftStatus.open,
      'openedBy': openedById,
      'openedByName': DemoNames.of(_findUser(openedById)),
      'openedAt': _now(),
      'openingCash': openingCash,
      'closedBy': null,
      'closedByName': null,
      'closedAt': null,
      'expectedCash': null,
      'countedCash': null,
      'variance': null,
      'note': null,
    };
    shifts.add(shift);
    return shift;
  }

  double _cashInDuring(int shiftId) => payments
      .where(
        (row) =>
            row['shiftId'] == shiftId && row['method'] == PaymentMethod.cash,
      )
      .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());

  /// mirror ของ shift.repository.js#cashRefundedDuring — ผูกด้วยกะที่เปิดอยู่ตอนคืน ไม่ใช่กะของ payment
  double _cashRefundedDuring(int shiftId) => refunds
      .where((row) {
        if (row['shiftId'] != shiftId) return false;
        final payment = payments.firstWhere((p) => p['id'] == row['paymentId']);
        return payment['method'] == PaymentMethod.cash;
      })
      .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());

  Map<String, dynamic> closeShift(
    int id, {
    required double countedCash,
    String? note,
    required int closedById,
  }) {
    final shift = shifts.firstWhere(
      (row) => row['id'] == id,
      orElse: () => throw ApiException(
        message: 'shift_error_not_found'.tr,
        statusCode: 404,
      ),
    );
    if (shift['status'] != ShiftStatus.open) {
      throw ApiException(
        message: 'shift_error_already_closed'.tr,
        statusCode: 409,
      );
    }

    // เงินทอนตั้งต้น + เงินสดที่รับเข้า (ค่าอาหาร + รับชำระหนี้ลูกค้าเครดิต) − เงินสดที่คืนลูกค้า
    // ออกไประหว่างกะนี้ (mirror ของ shift.service.js — docs/DECISIONS.md #44, #50)
    final expected =
        (shift['openingCash'] as num).toDouble() +
        _cashInDuring(id) +
        receivableCashDuring(id) -
        _cashRefundedDuring(id);
    shift['status'] = ShiftStatus.closed;
    shift['closedBy'] = closedById;
    shift['closedByName'] = DemoNames.of(_findUser(closedById));
    shift['closedAt'] = _now();
    shift['expectedCash'] = expected;
    shift['countedCash'] = countedCash;
    shift['variance'] = countedCash - expected;
    shift['note'] = note;
    return shift;
  }
}
