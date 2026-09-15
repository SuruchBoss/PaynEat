import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ingredient.dart';
import '../repositories/ingredient_repository.dart';

class GetIngredientsUseCase implements UseCase<List<Ingredient>, bool> {
  const GetIngredientsUseCase(this._repository);

  final IngredientRepository _repository;

  @override
  Future<Result<List<Ingredient>>> call(bool params) =>
      _repository.getIngredients(lowStockOnly: params);
}

/// ข้อมูลจากฟอร์มสร้าง/แก้ไขวัตถุดิบ — currentStock ใช้เฉพาะตอนสร้างใหม่เท่านั้น
/// (แก้ไขสต๊อกภายหลังต้องผ่าน [AdjustStockUseCase] เพื่อให้ sync สถานะเมนูที่เกี่ยวข้องเสมอ)
class IngredientFormData {
  const IngredientFormData({
    required this.name,
    required this.unit,
    this.currentStock = 0,
    this.lowStockThreshold = 0,
  });

  final String name;
  final String unit;
  final double currentStock;
  final double lowStockThreshold;

  Map<String, dynamic> toCreateJson() => {
    'name': name,
    'unit': unit,
    'currentStock': currentStock,
    'lowStockThreshold': lowStockThreshold,
  };

  Map<String, dynamic> toUpdateJson() => {
    'name': name,
    'unit': unit,
    'lowStockThreshold': lowStockThreshold,
  };
}

class SaveIngredientParams {
  const SaveIngredientParams({this.id, required this.data});

  final int? id;
  final IngredientFormData data;
}

class SaveIngredientUseCase
    implements UseCase<Ingredient, SaveIngredientParams> {
  const SaveIngredientUseCase(this._repository);

  final IngredientRepository _repository;

  @override
  Future<Result<Ingredient>> call(SaveIngredientParams params) {
    if (params.id == null) {
      return _repository.createIngredient(params.data.toCreateJson());
    }
    return _repository.updateIngredient(params.id!, params.data.toUpdateJson());
  }
}

class AdjustStockParams {
  const AdjustStockParams({required this.id, required this.delta});

  final int id;
  final double delta;
}

class AdjustStockUseCase implements UseCase<Ingredient, AdjustStockParams> {
  const AdjustStockUseCase(this._repository);

  final IngredientRepository _repository;

  @override
  Future<Result<Ingredient>> call(AdjustStockParams params) =>
      _repository.adjustStock(params.id, params.delta);
}

class DeleteIngredientUseCase implements UseCase<void, int> {
  const DeleteIngredientUseCase(this._repository);

  final IngredientRepository _repository;

  @override
  Future<Result<void>> call(int params) => _repository.deleteIngredient(params);
}
