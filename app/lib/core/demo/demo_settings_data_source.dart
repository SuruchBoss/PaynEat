// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

part of 'demo_data_sources.dart';

class DemoSettingsDataSource implements SettingsRemoteDataSource {
  const DemoSettingsDataSource(this._store, this._auth);

  final DemoStore _store;
  final DemoAuthDataSource _auth;

  StoreSettings _map(Map<String, dynamic> json) => StoreSettings(
    storeName: json['storeName'] as String,
    currency: json['currency'] as String,
    vatRate: (json['vatRate'] as num).toDouble(),
    serviceChargeRate: (json['serviceChargeRate'] as num).toDouble(),
    vatIncluded: json['vatIncluded'] as bool,
    storeTaxId: json['storeTaxId'] as String?,
    storeAddress: json['storeAddress'] as String?,
    storeBranch: json['storeBranch'] as String?,
    pointsEarnRateBaht: (json['pointsEarnRateBaht'] as num?)?.toDouble() ?? 25,
    pointsRedeemValueBaht:
        (json['pointsRedeemValueBaht'] as num?)?.toDouble() ?? 1,
    promptPayId: json['promptPayId'] as String?,
    scaleLabelPrefix: json['scaleLabelPrefix'] as String? ?? '20',
    scaleLabelPluDigits: (json['scaleLabelPluDigits'] as num?)?.toInt() ?? 5,
    lateFeeAnnualRatePercent:
        (json['lateFeeAnnualRatePercent'] as num?)?.toDouble() ?? 0,
    lateFeeGraceDays: (json['lateFeeGraceDays'] as num?)?.toInt() ?? 0,
    emailEnabled: json['emailEnabled'] as bool? ?? false,
  );

  @override
  Future<StoreSettings> get() => _delayed(() => _map(_store.settings));

  @override
  Future<StoreSettings> update(Map<String, dynamic> changes) => _delayed(
    () => _map(_store.updateSettings(changes, actorId: _auth.currentUserId)),
  );
}
