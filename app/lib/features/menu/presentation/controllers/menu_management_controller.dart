import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../data/models/menu_item_model.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/usecases/menu_usecases.dart';

/// จัดการเมนู (สำหรับผู้จัดการ/แอดมิน) — เพิ่ม แก้ไข ลบ และเปิด-ปิดการขาย
class MenuManagementController extends GetxController {
  MenuManagementController({
    required GetMenuItemsUseCase getMenuItems,
    required GetCategoriesUseCase getCategories,
    required CreateMenuItemUseCase createMenuItem,
    required UpdateMenuItemUseCase updateMenuItem,
    required DeleteMenuItemUseCase deleteMenuItem,
    required ToggleMenuAvailabilityUseCase toggleAvailability,
    required SaveCategoryUseCase saveCategory,
    required DeleteCategoryUseCase deleteCategory,
  })  : _getMenuItems = getMenuItems,
        _getCategories = getCategories,
        _createMenuItem = createMenuItem,
        _updateMenuItem = updateMenuItem,
        _deleteMenuItem = deleteMenuItem,
        _toggleAvailability = toggleAvailability,
        _saveCategory = saveCategory,
        _deleteCategory = deleteCategory;

  final GetMenuItemsUseCase _getMenuItems;
  final GetCategoriesUseCase _getCategories;
  final CreateMenuItemUseCase _createMenuItem;
  final UpdateMenuItemUseCase _updateMenuItem;
  final DeleteMenuItemUseCase _deleteMenuItem;
  final ToggleMenuAvailabilityUseCase _toggleAvailability;
  final SaveCategoryUseCase _saveCategory;
  final DeleteCategoryUseCase _deleteCategory;

  final RxList<MenuItem> items = <MenuItem>[].obs;
  final RxList<Category> categories = <Category>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnInt selectedCategoryId = RxnInt();
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  List<MenuItem> get filteredItems {
    final query = searchQuery.value.trim().toLowerCase();
    return items.where((item) {
      final categoryMatched =
          selectedCategoryId.value == null || item.categoryId == selectedCategoryId.value;
      if (!categoryMatched) return false;
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  int get unavailableCount => items.where((item) => !item.isAvailable).length;

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final results = await Future.wait([
      _getCategories(false),
      _getMenuItems(const MenuFilter()),
    ]);

    isLoading.value = false;
    results[0].fold(
      onSuccess: (data) => categories.assignAll(data as List<Category>),
      onFailure: (failure) => errorMessage.value = failure.message,
    );
    results[1].fold(
      onSuccess: (data) => items.assignAll(data as List<MenuItem>),
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  void selectCategory(int? id) => selectedCategoryId.value = id;
  void search(String query) => searchQuery.value = query;

  Future<void> toggleAvailability(MenuItem item) async {
    final result = await _toggleAvailability(
      ToggleAvailabilityParams(id: item.id, isAvailable: !item.isAvailable),
    );

    result.fold(
      onSuccess: (updated) {
        final index = items.indexWhere((row) => row.id == updated.id);
        if (index >= 0) items[index] = updated;
        AppDialogs.success(
          updated.isAvailable ? 'เปิดขาย "${updated.name}" แล้ว' : 'ปิดขาย "${updated.name}" แล้ว',
        );
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  Future<void> save({int? id, required MenuItemPayload payload}) async {
    isSaving.value = true;
    final result = id == null
        ? await _createMenuItem(payload)
        : await _updateMenuItem(UpdateMenuItemParams(id: id, payload: payload));
    isSaving.value = false;

    result.fold(
      onSuccess: (_) {
        AppDialogs.success(id == null ? 'เพิ่มเมนูใหม่แล้ว' : 'บันทึกการแก้ไขแล้ว');
        Get.back<void>();
        load();
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  Future<void> delete(MenuItem item) async {
    final confirmed = await AppDialogs.confirm(
      title: 'ลบเมนู',
      message: 'ต้องการลบ "${item.name}" ออกจากระบบใช่หรือไม่?',
      confirmLabel: 'ลบเมนู',
      destructive: true,
    );
    if (!confirmed) return;

    final result = await _deleteMenuItem(item.id);
    result.fold(
      onSuccess: (_) {
        items.removeWhere((row) => row.id == item.id);
        AppDialogs.success('ลบเมนูแล้ว');
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  Future<void> openForm({MenuItem? item}) async {
    await Get.toNamed<void>(AppRoutes.menuForm, arguments: {'item': item});
  }

  Future<void> saveCategory({int? id, required String name, String? icon}) async {
    final result = await _saveCategory(SaveCategoryParams(id: id, name: name, icon: icon));
    result.fold(
      onSuccess: (_) {
        AppDialogs.success(id == null ? 'เพิ่มหมวดหมู่แล้ว' : 'แก้ไขหมวดหมู่แล้ว');
        load();
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  Future<void> deleteCategory(Category category) async {
    final confirmed = await AppDialogs.confirm(
      title: 'ลบหมวดหมู่',
      message: 'ต้องการลบหมวดหมู่ "${category.name}" ใช่หรือไม่?',
      confirmLabel: 'ลบ',
      destructive: true,
    );
    if (!confirmed) return;

    final result = await _deleteCategory(category.id);
    result.fold(
      onSuccess: (_) {
        AppDialogs.success('ลบหมวดหมู่แล้ว');
        load();
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }
}
