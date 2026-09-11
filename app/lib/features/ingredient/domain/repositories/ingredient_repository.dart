import '../../../../core/usecases/result.dart';
import '../entities/ingredient.dart';

abstract class IngredientRepository {
  Future<Result<List<Ingredient>>> getIngredients({bool lowStockOnly});
  Future<Result<Ingredient>> getIngredient(int id);
  Future<Result<Ingredient>> createIngredient(Map<String, dynamic> payload);
  Future<Result<Ingredient>> updateIngredient(
    int id,
    Map<String, dynamic> changes,
  );
  Future<Result<Ingredient>> adjustStock(int id, double delta);
  Future<Result<void>> deleteIngredient(int id);
}
