import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/scale_status.dart';
import '../../domain/repositories/scale_repository.dart';
import '../datasources/scale_remote_data_source.dart';

class ScaleRepositoryImpl implements ScaleRepository {
  const ScaleRepositoryImpl(this._remote);

  final ScaleRemoteDataSource _remote;

  @override
  Future<Result<ScaleStatus>> status() => guard(_remote.status);

  @override
  Stream<ScaleStatus> watch() => _remote.watch();
}
