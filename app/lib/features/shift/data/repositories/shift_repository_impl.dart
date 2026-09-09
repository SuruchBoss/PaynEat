import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/shift.dart';
import '../../domain/repositories/shift_repository.dart';
import '../datasources/shift_remote_data_source.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  const ShiftRepositoryImpl(this._remote);

  final ShiftRemoteDataSource _remote;

  @override
  Future<Result<Shift?>> getCurrent() =>
      guard(() async => await _remote.getCurrent());

  @override
  Future<Result<Shift>> open(double openingCash) =>
      guard(() async => await _remote.open(openingCash));

  @override
  Future<Result<Shift>> close(
    int id, {
    required double countedCash,
    String? note,
  }) => guard(
    () async => await _remote.close(id, countedCash: countedCash, note: note),
  );

  @override
  Future<Result<List<Shift>>> getHistory() =>
      guard(() async => await _remote.getHistory());
}
