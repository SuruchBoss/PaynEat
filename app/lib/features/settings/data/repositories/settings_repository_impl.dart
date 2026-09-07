import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/store_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._remote);

  final SettingsRemoteDataSource _remote;

  @override
  Future<Result<StoreSettings>> get() => guard(() => _remote.get());

  @override
  Future<Result<StoreSettings>> update({
    String? storeName,
    double? vatRate,
    double? serviceChargeRate,
    bool? vatIncluded,
  }) => guard(
    () => _remote.update({
      'storeName': ?storeName,
      'vatRate': ?vatRate,
      'serviceChargeRate': ?serviceChargeRate,
      'vatIncluded': ?vatIncluded,
    }),
  );
}
