import '../../../../core/usecases/result.dart';
import '../../data/models/menu_item_model.dart';
import '../entities/category.dart';
import '../entities/menu_item.dart';

abstract class MenuRepository {
  Future<Result<List<Category>>> getCategories({bool activeOnly});
  Future<Result<Category>> createCategory({required String name, String? nameEn, String? icon});
  Future<Result<Category>> updateCategory(int id, Map<String, dynamic> changes);
  Future<Result<void>> deleteCategory(int id);

  Future<Result<List<MenuItem>>> getMenuItems({
    int? categoryId,
    String? search,
    bool? availableOnly,
  });
  Future<Result<MenuItem>> getMenuItem(int id);
  Future<Result<MenuItem>> createMenuItem(MenuItemPayload payload);
  Future<Result<MenuItem>> updateMenuItem(int id, MenuItemPayload payload);
  Future<Result<MenuItem>> setAvailability(int id, bool isAvailable);
  Future<Result<void>> deleteMenuItem(int id);
}
