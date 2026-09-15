part of 'demo_data_sources.dart';

class DemoIngredientDataSource implements IngredientRemoteDataSource {
  const DemoIngredientDataSource(this._store, this._auth);

  final DemoStore _store;
  final DemoAuthDataSource _auth;

  @override
  Future<List<IngredientModel>> getIngredients({bool lowStockOnly = false}) =>
      _delayed(
        () => _store
            .ingredientList(lowStockOnly: lowStockOnly)
            .map(IngredientModel.fromJson)
            .toList(growable: false),
      );

  @override
  Future<IngredientModel> getIngredient(int id) =>
      _delayed(() => IngredientModel.fromJson(_store.ingredient(id)));

  @override
  Future<IngredientModel> createIngredient(Map<String, dynamic> body) =>
      _delayed(() => IngredientModel.fromJson(_store.saveIngredient(body)));

  @override
  Future<IngredientModel> updateIngredient(int id, Map<String, dynamic> body) =>
      _delayed(
        () => IngredientModel.fromJson(_store.saveIngredient(body, id: id)),
      );

  @override
  Future<IngredientModel> adjustStock(int id, double delta) => _delayed(
    () => IngredientModel.fromJson(
      _store.adjustIngredientStock(id, delta, actorId: _auth.currentUserId),
    ),
  );

  @override
  Future<void> deleteIngredient(int id) =>
      _delayed(() => _store.deleteIngredient(id));
}
