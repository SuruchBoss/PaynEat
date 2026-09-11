import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/promotion_model.dart';

abstract class PromotionRemoteDataSource {
  Future<List<PromotionModel>> getPromotions({bool activeOnly});
  Future<PromotionModel> getPromotion(int id);
  Future<PromotionModel> createPromotion(Map<String, dynamic> body);
  Future<PromotionModel> updatePromotion(int id, Map<String, dynamic> body);
  Future<void> deletePromotion(int id);
}

class PromotionRemoteDataSourceImpl implements PromotionRemoteDataSource {
  const PromotionRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<PromotionModel>> getPromotions({bool activeOnly = false}) async {
    final result = await _client.get(
      ApiEndpoints.promotions,
      query: {if (activeOnly) 'activeOnly': 'true'},
    );
    return result.asList.map(PromotionModel.fromJson).toList(growable: false);
  }

  @override
  Future<PromotionModel> getPromotion(int id) async {
    final result = await _client.get(ApiEndpoints.promotion(id));
    return PromotionModel.fromJson(result.asMap);
  }

  @override
  Future<PromotionModel> createPromotion(Map<String, dynamic> body) async {
    final result = await _client.post(ApiEndpoints.promotions, body: body);
    return PromotionModel.fromJson(result.asMap);
  }

  @override
  Future<PromotionModel> updatePromotion(
    int id,
    Map<String, dynamic> body,
  ) async {
    final result = await _client.patch(ApiEndpoints.promotion(id), body: body);
    return PromotionModel.fromJson(result.asMap);
  }

  @override
  Future<void> deletePromotion(int id) =>
      _client.delete(ApiEndpoints.promotion(id));
}
