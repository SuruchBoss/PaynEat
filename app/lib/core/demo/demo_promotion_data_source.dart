// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

part of 'demo_data_sources.dart';

class DemoPromotionDataSource implements PromotionRemoteDataSource {
  const DemoPromotionDataSource(this._store, this._auth);

  final DemoStore _store;
  final DemoAuthDataSource _auth;

  @override
  Future<List<PromotionModel>> getPromotions({bool activeOnly = false}) =>
      _delayed(
        () => _store
            .promotionList(activeOnly: activeOnly)
            .map(PromotionModel.fromJson)
            .toList(growable: false),
      );

  @override
  Future<PromotionModel> getPromotion(int id) =>
      _delayed(() => PromotionModel.fromJson(_store.promotion(id)));

  @override
  Future<PromotionModel> createPromotion(Map<String, dynamic> body) => _delayed(
    () => PromotionModel.fromJson(
      _store.savePromotion(body, actorId: _auth.currentUserId),
    ),
  );

  @override
  Future<PromotionModel> updatePromotion(int id, Map<String, dynamic> body) =>
      _delayed(
        () => PromotionModel.fromJson(
          _store.savePromotion(body, id: id, actorId: _auth.currentUserId),
        ),
      );

  @override
  Future<void> deletePromotion(int id) =>
      _delayed(() => _store.deletePromotion(id, actorId: _auth.currentUserId));
}
