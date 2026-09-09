import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/shift.dart';
import '../repositories/shift_repository.dart';

class GetCurrentShiftUseCase implements NoParamsUseCase<Shift?> {
  const GetCurrentShiftUseCase(this._repository);

  final ShiftRepository _repository;

  @override
  Future<Result<Shift?>> call() => _repository.getCurrent();
}

class OpenShiftUseCase implements UseCase<Shift, double> {
  const OpenShiftUseCase(this._repository);

  final ShiftRepository _repository;

  @override
  Future<Result<Shift>> call(double openingCash) =>
      _repository.open(openingCash);
}

class CloseShiftParams {
  const CloseShiftParams({
    required this.id,
    required this.countedCash,
    this.note,
  });

  final int id;
  final double countedCash;
  final String? note;
}

class CloseShiftUseCase implements UseCase<Shift, CloseShiftParams> {
  const CloseShiftUseCase(this._repository);

  final ShiftRepository _repository;

  @override
  Future<Result<Shift>> call(CloseShiftParams params) => _repository.close(
    params.id,
    countedCash: params.countedCash,
    note: params.note,
  );
}

class GetShiftHistoryUseCase implements NoParamsUseCase<List<Shift>> {
  const GetShiftHistoryUseCase(this._repository);

  final ShiftRepository _repository;

  @override
  Future<Result<List<Shift>>> call() => _repository.getHistory();
}
