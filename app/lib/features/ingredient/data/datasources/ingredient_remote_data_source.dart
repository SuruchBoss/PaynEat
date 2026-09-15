import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ingredient_model.dart';

abstract class IngredientRemoteDataSource {
  Future<List<IngredientModel>> getIngredients({bool lowStockOnly});
  Future<IngredientModel> getIngredient(int id);
  Future<IngredientModel> createIngredient(Map<String, dynamic> body);
  Future<IngredientModel> updateIngredient(int id, Map<String, dynamic> body);
  Future<IngredientModel> adjustStock(int id, double delta);
  Future<void> deleteIngredient(int id);
}

class IngredientRemoteDataSourceImpl implements IngredientRemoteDataSource {
  const IngredientRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<IngredientModel>> getIngredients({
    bool lowStockOnly = false,
  }) async {
    final result = await _client.get(
      ApiEndpoints.ingredients,
      query: {if (lowStockOnly) 'lowStockOnly': 'true'},
    );
    return result.asList.map(IngredientModel.fromJson).toList(growable: false);
  }

  @override
  Future<IngredientModel> getIngredient(int id) async {
    final result = await _client.get(ApiEndpoints.ingredient(id));
    return IngredientModel.fromJson(result.asMap);
  }

  @override
  Future<IngredientModel> createIngredient(Map<String, dynamic> body) async {
    final result = await _client.post(ApiEndpoints.ingredients, body: body);
    return IngredientModel.fromJson(result.asMap);
  }

  @override
  Future<IngredientModel> updateIngredient(
    int id,
    Map<String, dynamic> body,
  ) async {
    final result = await _client.patch(ApiEndpoints.ingredient(id), body: body);
    return IngredientModel.fromJson(result.asMap);
  }

  @override
  Future<IngredientModel> adjustStock(int id, double delta) async {
    final result = await _client.post(
      ApiEndpoints.ingredientAdjustStock(id),
      body: {'delta': delta},
    );
    return IngredientModel.fromJson(result.asMap);
  }

  @override
  Future<void> deleteIngredient(int id) =>
      _client.delete(ApiEndpoints.ingredient(id));
}
