import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/menu_item_model.dart';
import '../entities/category.dart';
import '../entities/menu_item.dart';
import '../repositories/menu_repository.dart';

/// พารามิเตอร์สำหรับกรองเมนู
class MenuFilter {
  const MenuFilter({this.categoryId, this.search, this.availableOnly});

  final int? categoryId;
  final String? search;
  final bool? availableOnly;
}

/// ดึงรายการเมนู (ใช้ทั้งหน้าสั่งอาหารและหน้าจัดการเมนู)
class GetMenuItemsUseCase implements UseCase<List<MenuItem>, MenuFilter> {
  const GetMenuItemsUseCase(this._repository);

  final MenuRepository _repository;

  @override
  Future<Result<List<MenuItem>>> call(MenuFilter params) =>
      _repository.getMenuItems(
        categoryId: params.categoryId,
        search: params.search,
        availableOnly: params.availableOnly,
      );
}

/// ดึงหมวดหมู่ทั้งหมด
class GetCategoriesUseCase implements UseCase<List<Category>, bool> {
  const GetCategoriesUseCase(this._repository);

  final MenuRepository _repository;

  @override
  Future<Result<List<Category>>> call(bool activeOnly) =>
      _repository.getCategories(activeOnly: activeOnly);
}

/// เพิ่มเมนูใหม่ (ผู้จัดการ)
class CreateMenuItemUseCase implements UseCase<MenuItem, MenuItemPayload> {
  const CreateMenuItemUseCase(this._repository);

  final MenuRepository _repository;

  @override
  Future<Result<MenuItem>> call(MenuItemPayload params) =>
      _repository.createMenuItem(params);
}

class UpdateMenuItemParams {
  const UpdateMenuItemParams({required this.id, required this.payload});

  final int id;
  final MenuItemPayload payload;
}

/// แก้ไขเมนู (ผู้จัดการ)
class UpdateMenuItemUseCase implements UseCase<MenuItem, UpdateMenuItemParams> {
  const UpdateMenuItemUseCase(this._repository);

  final MenuRepository _repository;

  @override
  Future<Result<MenuItem>> call(UpdateMenuItemParams params) =>
      _repository.updateMenuItem(params.id, params.payload);
}

class ToggleAvailabilityParams {
  const ToggleAvailabilityParams({required this.id, required this.isAvailable});

  final int id;
  final bool isAvailable;
}

/// เปิด/ปิดการขายเมนู — ใช้ตอนของหมดกลางวัน
class ToggleMenuAvailabilityUseCase
    implements UseCase<MenuItem, ToggleAvailabilityParams> {
  const ToggleMenuAvailabilityUseCase(this._repository);

  final MenuRepository _repository;

  @override
  Future<Result<MenuItem>> call(ToggleAvailabilityParams params) =>
      _repository.setAvailability(params.id, params.isAvailable);
}

/// ลบเมนู
class DeleteMenuItemUseCase implements UseCase<void, int> {
  const DeleteMenuItemUseCase(this._repository);

  final MenuRepository _repository;

  @override
  Future<Result<void>> call(int params) => _repository.deleteMenuItem(params);
}

/// จัดการหมวดหมู่
class SaveCategoryParams {
  const SaveCategoryParams({
    this.id,
    required this.name,
    this.nameEn,
    this.icon,
  });

  final int? id;
  final String name;
  final String? nameEn;
  final String? icon;
}

class SaveCategoryUseCase implements UseCase<Category, SaveCategoryParams> {
  const SaveCategoryUseCase(this._repository);

  final MenuRepository _repository;

  @override
  Future<Result<Category>> call(SaveCategoryParams params) {
    if (params.id == null) {
      return _repository.createCategory(
        name: params.name,
        nameEn: params.nameEn,
        icon: params.icon,
      );
    }
    return _repository.updateCategory(params.id!, {
      'name': params.name,
      if (params.nameEn != null) 'nameEn': params.nameEn,
      if (params.icon != null) 'icon': params.icon,
    });
  }
}

class DeleteCategoryUseCase implements UseCase<void, int> {
  const DeleteCategoryUseCase(this._repository);

  final MenuRepository _repository;

  @override
  Future<Result<void>> call(int params) => _repository.deleteCategory(params);
}
