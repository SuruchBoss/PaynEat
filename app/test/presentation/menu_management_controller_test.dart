import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/menu/domain/entities/category.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/menu/domain/repositories/menu_repository.dart';
import 'package:payneat_pos/features/menu/domain/usecases/menu_usecases.dart';
import 'package:payneat_pos/features/menu/presentation/controllers/menu_management_controller.dart';

class _FakeMenuRepository implements MenuRepository {
  Result<List<Category>> nextCategoriesResult = const Result.success([]);
  Result<List<MenuItem>> nextMenuItemsResult = const Result.success([]);

  @override
  Future<Result<List<Category>>> getCategories({
    bool activeOnly = true,
  }) async => nextCategoriesResult;

  @override
  Future<Result<List<MenuItem>>> getMenuItems({
    int? categoryId,
    String? search,
    bool? availableOnly,
  }) async => nextMenuItemsResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MenuItem _item(
  int id, {
  int categoryId = 1,
  String name = 'ข้าวผัด',
  bool isAvailable = true,
}) => MenuItem(
  id: id,
  categoryId: categoryId,
  name: name,
  price: 50,
  isAvailable: isAvailable,
);

void main() {
  late _FakeMenuRepository repository;
  late MenuManagementController controller;

  setUp(() {
    repository = _FakeMenuRepository();
    controller = MenuManagementController(
      getMenuItems: GetMenuItemsUseCase(repository),
      getCategories: GetCategoriesUseCase(repository),
      createMenuItem: CreateMenuItemUseCase(repository),
      updateMenuItem: UpdateMenuItemUseCase(repository),
      deleteMenuItem: DeleteMenuItemUseCase(repository),
      toggleAvailability: ToggleMenuAvailabilityUseCase(repository),
      saveCategory: SaveCategoryUseCase(repository),
      deleteCategory: DeleteCategoryUseCase(repository),
    );
  });

  tearDown(() => controller.onClose());

  group('MenuManagementController', () {
    // toggleAvailability/save/delete/openForm/saveCategory/deleteCategory ทุกเส้นทางแตะ
    // AppDialogs หรือ Get.toNamed จึงต้องมี GetMaterialApp ที่ pump จริง ไม่ครอบคลุมในเทสต์
    // ระดับ unit นี้ (ดู docs/CODING_STANDARDS.md) — ทดสอบเฉพาะส่วนที่ไม่แตะ Get.*

    test('load สำเร็จ → เติมทั้งเมนูและหมวดหมู่ ปิด loading', () async {
      repository.nextCategoriesResult = const Result.success([
        Category(id: 1, name: 'จานเดียว'),
      ]);
      repository.nextMenuItemsResult = Result.success([_item(1), _item(2)]);

      await controller.load();

      expect(controller.items.length, 2);
      expect(controller.categories.length, 1);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isNull);
    });

    test('load ล้มเหลว → ตั้ง errorMessage', () async {
      repository.nextMenuItemsResult = const Result.failure(
        NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
      );

      await controller.load();

      expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
    });

    test('filteredItems กรองตามหมวดหมู่และคำค้นหาพร้อมกัน', () async {
      repository.nextMenuItemsResult = Result.success([
        _item(1, categoryId: 1, name: 'ข้าวผัดหมู'),
        _item(2, categoryId: 1, name: 'ต้มยำกุ้ง'),
        _item(3, categoryId: 2, name: 'ข้าวผัดปู'),
      ]);
      await controller.load();

      controller.selectCategory(1);
      expect(controller.filteredItems.map((i) => i.id), [1, 2]);

      controller.search('ข้าวผัด');
      expect(controller.filteredItems.map((i) => i.id), [1]);

      controller.selectCategory(null);
      expect(controller.filteredItems.map((i) => i.id), [1, 3]);
    });

    test('unavailableCount นับเฉพาะเมนูที่ปิดขาย', () async {
      repository.nextMenuItemsResult = Result.success([
        _item(1, isAvailable: true),
        _item(2, isAvailable: false),
        _item(3, isAvailable: false),
      ]);
      await controller.load();

      expect(controller.unavailableCount, 2);
    });
  });
}
