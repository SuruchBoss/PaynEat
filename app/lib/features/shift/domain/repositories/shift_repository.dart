import '../../../../core/usecases/result.dart';
import '../entities/shift.dart';

abstract class ShiftRepository {
  /// กะที่เปิดอยู่ตอนนี้ (null ถ้าไม่มี)
  Future<Result<Shift?>> getCurrent();

  Future<Result<Shift>> open(double openingCash);

  Future<Result<Shift>> close(
    int id, {
    required double countedCash,
    String? note,
  });

  Future<Result<List<Shift>>> getHistory();
}
