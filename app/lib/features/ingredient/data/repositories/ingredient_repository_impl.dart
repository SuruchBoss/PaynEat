import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/repositories/ingredient_repository.dart';
import '../datasources/ingredient_remote_data_source.dart';

class IngredientRepositoryImpl implements IngredientRepository {
  const IngredientRepositoryImpl(this._remote);

  final IngredientRemoteDataSource _remote;

  @override
  Future<Result<List<Ingredient>>> getIngredients({
    bool lowStockOnly = false,
  }) => guard(
    () async => await _remote.getIngredients(lowStockOnly: lowStockOnly),
  );

  @override
  Future<Result<Ingredient>> getIngredient(int id) =>
      guard(() async => await _remote.getIngredient(id));

  @override
  Future<Result<Ingredient>> createIngredient(Map<String, dynamic> payload) =>
      guard(() async => await _remote.createIngredient(payload));

  @override
  Future<Result<Ingredient>> updateIngredient(
    int id,
    Map<String, dynamic> changes,
  ) => guard(() async => await _remote.updateIngredient(id, changes));

  @override
  Future<Result<Ingredient>> adjustStock(int id, double delta) =>
      guard(() async => await _remote.adjustStock(id, delta));

  @override
  Future<Result<void>> deleteIngredient(int id) =>
      guard(() => _remote.deleteIngredient(id));
}
