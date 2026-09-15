import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/store_settings.dart';

abstract class SettingsRemoteDataSource {
  Future<StoreSettings> get();
  Future<StoreSettings> update(Map<String, dynamic> changes);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  const SettingsRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  static StoreSettings _fromJson(Map<String, dynamic> json) => StoreSettings(
    storeName: json['storeName'] as String? ?? '',
    currency: json['currency'] as String? ?? 'THB',
    vatRate: (json['vatRate'] as num?)?.toDouble() ?? 0,
    serviceChargeRate: (json['serviceChargeRate'] as num?)?.toDouble() ?? 0,
    vatIncluded: json['vatIncluded'] as bool? ?? false,
    storeTaxId: json['storeTaxId'] as String?,
    storeAddress: json['storeAddress'] as String?,
    storeBranch: json['storeBranch'] as String?,
  );

  @override
  Future<StoreSettings> get() async {
    final result = await _client.get(ApiEndpoints.settings);
    return _fromJson(result.asMap);
  }

  @override
  Future<StoreSettings> update(Map<String, dynamic> changes) async {
    final result = await _client.patch(ApiEndpoints.settings, body: changes);
    return _fromJson(result.asMap);
  }
}
