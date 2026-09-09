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
      throw const ApiException(
        message: 'มีกะที่เปิดอยู่แล้ว ต้องปิดกะเดิมก่อนเปิดกะใหม่',
        statusCode: 409,
      );
    }
    final shift = {
      'id': _nextId(),
      'status': ShiftStatus.open,
      'openedBy': openedById,
      'openedByName': _findUser(openedById)['name'],
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

  Map<String, dynamic> closeShift(
    int id, {
    required double countedCash,
    String? note,
    required int closedById,
  }) {
    final shift = shifts.firstWhere(
      (row) => row['id'] == id,
      orElse: () =>
          throw const ApiException(message: 'ไม่พบกะนี้', statusCode: 404),
    );
    if (shift['status'] != ShiftStatus.open) {
      throw const ApiException(message: 'กะนี้ปิดไปแล้ว', statusCode: 409);
    }

    final expected =
        (shift['openingCash'] as num).toDouble() + _cashInDuring(id);
    shift['status'] = ShiftStatus.closed;
    shift['closedBy'] = closedById;
    shift['closedByName'] = _findUser(closedById)['name'];
    shift['closedAt'] = _now();
    shift['expectedCash'] = expected;
    shift['countedCash'] = countedCash;
    shift['variance'] = countedCash - expected;
    shift['note'] = note;
    return shift;
  }
}
