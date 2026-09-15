part of 'demo_store.dart';

// ------------------------------------------------------------ menu ------
extension DemoStoreMenu on DemoStore {
  List<Map<String, dynamic>> categoryList() => categories
      .map(
        (category) => {
          ...category,
          'itemCount': menuItems
              .where((item) => item['categoryId'] == category['id'])
              .length,
        },
      )
      .toList(growable: false);

  Map<String, dynamic> saveCategory(Map<String, dynamic> body, {int? id}) {
    if (id == null) {
      final category = {
        'id': _nextId(),
        'name': body['name'],
        'nameEn': body['nameEn'],
        'icon': body['icon'],
        'sortOrder': categories.length + 1,
        'isActive': true,
      };
      categories.add(category);
      return category;
    }
    final category = categories.firstWhere((row) => row['id'] == id);
    body.forEach((key, value) => category[key] = value);
    return category;
  }

  void deleteCategory(int id) {
    if (menuItems.any((item) => item['categoryId'] == id)) {
      throw ApiException(
        message: 'menu_delete_category_has_items_error'.tr,
        statusCode: 409,
      );
    }
    categories.removeWhere((row) => row['id'] == id);
  }

  List<Map<String, dynamic>> menuList({
    int? categoryId,
    String? search,
    bool? availableOnly,
  }) {
    return menuItems
        .where((item) {
          if (categoryId != null && item['categoryId'] != categoryId) {
            return false;
          }
          if (availableOnly == true && item['isAvailable'] != true) {
            return false;
          }
          if (search != null && search.isNotEmpty) {
            final name = (item['name'] as String).toLowerCase();
            if (!name.contains(search.toLowerCase())) return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Map<String, dynamic> menuItem(int id) => menuItems.firstWhere(
    (row) => row['id'] == id,
    orElse: () => throw ApiException(
      message: 'menu_item_not_found_error'.tr,
      statusCode: 404,
    ),
  );

  Map<String, dynamic> saveMenuItem(Map<String, dynamic> body, {int? id}) {
    final categoryName = categories.firstWhere(
      (row) => row['id'] == body['categoryId'],
      orElse: () => categories.first,
    )['name'];

    if (id == null) {
      final item = {
        'id': _nextId(),
        'categoryId': body['categoryId'],
        'categoryName': categoryName,
        'name': body['name'],
        'nameEn': body['nameEn'],
        'description': body['description'],
        'price': body['price'],
        'imageUrl': body['imageUrl'],
        'isAvailable': body['isAvailable'] ?? true,
        'isRecommended': body['isRecommended'] ?? false,
        'prepMinutes': body['prepMinutes'] ?? 10,
        'sortOrder': menuItems.length + 1,
        'optionGroups': _normalizeOptionGroups(body['optionGroups']),
        'ingredients': _normalizeIngredientLinks(body['ingredients']),
        'autoDisabledByStock': false,
      };
      menuItems.add(item);
      return item;
    }

    final item = menuItem(id);
    body.forEach((key, value) {
      if (key == 'optionGroups') {
        item[key] = _normalizeOptionGroups(value);
      } else if (key == 'ingredients') {
        item[key] = _normalizeIngredientLinks(value);
      } else {
        item[key] = value;
      }
    });
    item['categoryName'] = categoryName;
    // แก้ isAvailable เองผ่านฟอร์ม ถือเป็นการ override ระบบตัดสต๊อกอัตโนมัติ
    if (body.containsKey('isAvailable')) {
      item['autoDisabledByStock'] = false;
    }
    return item;
  }

  /// วัตถุดิบที่ผูกไว้ต้องมีอยู่จริงและห้ามซ้ำกันในเมนูเดียว — denormalize
  /// ชื่อ/หน่วยไว้ตรง ๆ เหมือน categoryName (ดู docs/tickets/06-inventory-stock.md)
  List<Map<String, dynamic>> _normalizeIngredientLinks(dynamic links) {
    if (links is! List) return const [];
    final seen = <int>{};
    return links
        .whereType<Map<String, dynamic>>()
        .map((link) {
          final ingredientId = link['ingredientId'] as int;
          if (!seen.add(ingredientId)) {
            throw ApiException(
              message: 'ingredient_error_duplicate_link'.tr,
              statusCode: 422,
            );
          }
          final ingredient = ingredients.firstWhere(
            (row) => row['id'] == ingredientId,
            orElse: () => throw ApiException(
              message: 'ingredient_error_link_not_found'.tr,
              statusCode: 400,
            ),
          );
          return {
            'ingredientId': ingredientId,
            'ingredientName': ingredient['name'],
            'unit': ingredient['unit'],
            'qtyPerUnit': (link['qtyPerUnit'] as num).toDouble(),
          };
        })
        .toList(growable: false);
  }

  /// ตัวเลือกที่ส่งมาจากฟอร์มยังไม่มี id จริง — ออก id ให้เหมือนที่ backend ทำ
  List<Map<String, dynamic>> _normalizeOptionGroups(dynamic groups) {
    if (groups is! List) return const [];
    return groups
        .whereType<Map<String, dynamic>>()
        .map((group) {
          return {
            'id': _nextId(),
            'name': group['name'],
            'minSelect': group['minSelect'] ?? 0,
            'maxSelect': group['maxSelect'] ?? 1,
            'isRequired': group['isRequired'] ?? false,
            'options': (group['options'] as List? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(
                  (option) => {
                    'id': _nextId(),
                    'name': option['name'],
                    'priceDelta': option['priceDelta'] ?? 0,
                    'isDefault': option['isDefault'] ?? false,
                  },
                )
                .toList(growable: false),
          };
        })
        .toList(growable: false);
  }

  Map<String, dynamic> setAvailability(int id, bool isAvailable) {
    final item = menuItem(id);
    item['isAvailable'] = isAvailable;
    item['autoDisabledByStock'] = false;
    return item;
  }

  void deleteMenuItem(int id) =>
      menuItems.removeWhere((row) => row['id'] == id);
}
