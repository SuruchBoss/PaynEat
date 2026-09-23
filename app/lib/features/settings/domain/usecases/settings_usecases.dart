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
    this.pointsEarnRateBaht,
    this.pointsRedeemValueBaht,
    this.promptPayId,
    this.scaleLabelPrefix,
    this.scaleLabelPluDigits,
    this.lateFeeAnnualRatePercent,
    this.lateFeeGraceDays,
  });

  final String? storeName;
  final double? vatRate;
  final double? serviceChargeRate;
  final bool? vatIncluded;
  final String? storeTaxId;
  final String? storeAddress;
  final String? storeBranch;
  final double? pointsEarnRateBaht;
  final double? pointsRedeemValueBaht;
  final String? promptPayId;
  final String? scaleLabelPrefix;
  final int? scaleLabelPluDigits;
  final double? lateFeeAnnualRatePercent;
  final int? lateFeeGraceDays;
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
        pointsEarnRateBaht: params.pointsEarnRateBaht,
        pointsRedeemValueBaht: params.pointsRedeemValueBaht,
        promptPayId: params.promptPayId,
        scaleLabelPrefix: params.scaleLabelPrefix,
        scaleLabelPluDigits: params.scaleLabelPluDigits,
        lateFeeAnnualRatePercent: params.lateFeeAnnualRatePercent,
        lateFeeGraceDays: params.lateFeeGraceDays,
      );
}
