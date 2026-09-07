import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/menu_remote_data_source.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';

class MenuRepositoryImpl implements MenuRepository {
  const MenuRepositoryImpl(this._remote);

  final MenuRemoteDataSource _remote;

  @override
  Future<Result<List<Category>>> getCategories({bool activeOnly = false}) =>
      guard(() async => await _remote.getCategories(activeOnly: activeOnly));

  @override
  Future<Result<Category>> createCategory({
    required String name,
    String? nameEn,
    String? icon,
  }) =>
      guard(
        () async => await _remote.createCategory(
          CategoryModel.toCreateJson(name: name, nameEn: nameEn, icon: icon),
        ),
      );

  @override
  Future<Result<Category>> updateCategory(int id, Map<String, dynamic> changes) =>
      guard(() async => await _remote.updateCategory(id, changes));

  @override
  Future<Result<void>> deleteCategory(int id) => guard(() => _remote.deleteCategory(id));

  @override
  Future<Result<List<MenuItem>>> getMenuItems({
    int? categoryId,
    String? search,
    bool? availableOnly,
  }) =>
      guard(
        () async => await _remote.getMenuItems(
          categoryId: categoryId,
          search: search,
          availableOnly: availableOnly,
        ),
      );

  @override
  Future<Result<MenuItem>> getMenuItem(int id) =>
      guard(() async => await _remote.getMenuItem(id));

  @override
  Future<Result<MenuItem>> createMenuItem(MenuItemPayload payload) =>
      guard(() async => await _remote.createMenuItem(payload));

  @override
  Future<Result<MenuItem>> updateMenuItem(int id, MenuItemPayload payload) =>
      guard(() async => await _remote.updateMenuItem(id, payload));

  @override
  Future<Result<MenuItem>> setAvailability(int id, bool isAvailable) =>
      guard(() async => await _remote.setAvailability(id, isAvailable));

  @override
  Future<Result<void>> deleteMenuItem(int id) => guard(() => _remote.deleteMenuItem(id));
}
