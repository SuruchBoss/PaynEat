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
      throw const ApiException(
        message: 'ลบไม่ได้ เพราะยังมีเมนูอยู่ในหมวดหมู่นี้',
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
    orElse: () =>
        throw const ApiException(message: 'ไม่พบเมนูนี้', statusCode: 404),
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
        'imageUrl': null,
        'isAvailable': body['isAvailable'] ?? true,
        'isRecommended': body['isRecommended'] ?? false,
        'prepMinutes': body['prepMinutes'] ?? 10,
        'sortOrder': menuItems.length + 1,
        'optionGroups': _normalizeOptionGroups(body['optionGroups']),
      };
      menuItems.add(item);
      return item;
    }

    final item = menuItem(id);
    body.forEach((key, value) {
      if (key == 'optionGroups') {
        item[key] = _normalizeOptionGroups(value);
      } else {
        item[key] = value;
      }
    });
    item['categoryName'] = categoryName;
    return item;
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
    return item;
  }

  void deleteMenuItem(int id) =>
      menuItems.removeWhere((row) => row['id'] == id);
}
