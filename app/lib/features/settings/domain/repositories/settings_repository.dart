import '../../../../core/usecases/result.dart';
import '../entities/store_settings.dart';

abstract class SettingsRepository {
  Future<Result<StoreSettings>> get();
  Future<Result<StoreSettings>> update({
    String? storeName,
    double? vatRate,
    double? serviceChargeRate,
    bool? vatIncluded,
    String? storeTaxId,
    String? storeAddress,
    String? storeBranch,
  });
}
