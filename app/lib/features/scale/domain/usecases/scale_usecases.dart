import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/scale_status.dart';
import '../repositories/scale_repository.dart';

class GetScaleStatusUseCase implements NoParamsUseCase<ScaleStatus> {
  const GetScaleStatusUseCase(this._repository);

  final ScaleRepository _repository;

  @override
  Future<Result<ScaleStatus>> call() => _repository.status();
}

class WatchScaleUseCase {
  const WatchScaleUseCase(this._repository);

  final ScaleRepository _repository;

  Stream<ScaleStatus> call() => _repository.watch();
}
