import '../../domain/entities/ingredient.dart';

class IngredientModel extends Ingredient {
  const IngredientModel({
    required super.id,
    required super.name,
    required super.unit,
    super.currentStock,
    super.lowStockThreshold,
    super.createdAt,
    super.updatedAt,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) =>
      IngredientModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0,
        lowStockThreshold: (json['lowStockThreshold'] as num?)?.toDouble() ?? 0,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );
}

class MenuItemIngredientUsageModel extends MenuItemIngredientUsage {
  const MenuItemIngredientUsageModel({
    required super.ingredientId,
    required super.qtyPerUnit,
    super.ingredientName,
    super.unit,
  });

  factory MenuItemIngredientUsageModel.fromJson(Map<String, dynamic> json) =>
      MenuItemIngredientUsageModel(
        ingredientId: (json['ingredientId'] as num).toInt(),
        qtyPerUnit: (json['qtyPerUnit'] as num?)?.toDouble() ?? 0,
        ingredientName: json['ingredientName'] as String?,
        unit: json['unit'] as String?,
      );
}
