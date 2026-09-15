import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/store_settings.dart';
import '../repositories/settings_repository.dart';

class GetSettingsUseCase implements NoParamsUseCase<StoreSettings> {
  const GetSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<StoreSettings>> call() => _repository.get();
}

class UpdateSettingsParams {
  const UpdateSettingsParams({
    this.storeName,
    this.vatRate,
    this.serviceChargeRate,
    this.vatIncluded,
    this.storeTaxId,
    this.storeAddress,
    this.storeBranch,
  });

  final String? storeName;
  final double? vatRate;
  final double? serviceChargeRate;
  final bool? vatIncluded;
  final String? storeTaxId;
  final String? storeAddress;
  final String? storeBranch;
}

class UpdateSettingsUseCase
    implements UseCase<StoreSettings, UpdateSettingsParams> {
  const UpdateSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<StoreSettings>> call(UpdateSettingsParams params) =>
      _repository.update(
        storeName: params.storeName,
        vatRate: params.vatRate,
        serviceChargeRate: params.serviceChargeRate,
        vatIncluded: params.vatIncluded,
        storeTaxId: params.storeTaxId,
        storeAddress: params.storeAddress,
        storeBranch: params.storeBranch,
      );
}
