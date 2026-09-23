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
            // บาร์โค้ดต้องตรงทั้งรหัส (mirror ของ menu.repository.js#findAll)
            if (!name.contains(search.toLowerCase()) &&
                item['barcode'] != search) {
              return false;
            }
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

  Map<String, dynamic> saveMenuItem(
    Map<String, dynamic> body, {
    int? id,
    int? actorId,
  }) {
    final categoryName = categories.firstWhere(
      (row) => row['id'] == body['categoryId'],
      orElse: () => categories.first,
    )['name'];
    final soldByWeight =
        body['soldByWeight'] as bool? ??
        (id == null ? false : menuItem(id)['soldByWeight'] as bool? ?? false);
    final codes = _normalizeMenuCodes(body, id: id, soldByWeight: soldByWeight);

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
        'soldByWeight': soldByWeight,
        'barcode': codes['barcode'],
        'scalePlu': codes['scalePlu'],
      };
      menuItems.add(item);
      return item;
    }

    final item = menuItem(id);
    final previousPrice = (item['price'] as num?)?.toDouble();
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
    item.addAll(codes);
    // แก้ isAvailable เองผ่านฟอร์ม ถือเป็นการ override ระบบตัดสต๊อกอัตโนมัติ
    if (body.containsKey('isAvailable')) {
      item['autoDisabledByStock'] = false;
    }

    // mirror ของ menu.service.js#update — log เฉพาะตอนราคาเปลี่ยนจริงเท่านั้น (ดู
    // docs/tickets/14-financial-audit-trail.md)
    final newPrice = body['price'] == null
        ? null
        : (body['price'] as num).toDouble();
    if (newPrice != null && newPrice != previousPrice) {
      _logAudit(
        actorId: actorId,
        action: 'menu.price_change',
        entityType: 'menu_item',
        entityId: id,
        summary: 'แก้ราคาเมนู "${item['name']}" $previousPrice → $newPrice บาท',
        metadata: {'previousPrice': previousPrice, 'newPrice': newPrice},
      );
    }
    return item;
  }

  /// mirror ของ menu.service.js#normalizeCodes (ดู docs/tickets/19-barcode-scale.md) — คืนเฉพาะ
  /// ช่องที่ต้องเขียนทับ ('' → null = ล้างค่า) PLU ตัดเลข 0 นำหน้าให้ตรงกับที่อ่านจากฉลาก
  Map<String, dynamic> _normalizeMenuCodes(
    Map<String, dynamic> body, {
    int? id,
    required bool soldByWeight,
  }) {
    final patch = <String, dynamic>{};
    if (body.containsKey('barcode')) {
      final code = (body['barcode'] as String?)?.trim() ?? '';
      patch['barcode'] = code.isEmpty ? null : code;
    }
    if (body.containsKey('scalePlu')) {
      final plu = (body['scalePlu'] as String?)?.trim() ?? '';
      patch['scalePlu'] = plu.isEmpty ? null : int.parse(plu).toString();
    }
    if (patch['scalePlu'] != null && !soldByWeight) {
      throw ApiException(
        message: 'menu_error_plu_requires_weight'.tr,
        statusCode: 400,
      );
    }
    if (!soldByWeight &&
        !body.containsKey('scalePlu') &&
        body['soldByWeight'] == false) {
      patch['scalePlu'] = null;
    }
    for (final field in const ['barcode', 'scalePlu']) {
      final value = patch[field];
      if (value == null) continue;
      for (final row in menuItems) {
        if (row['id'] != id && row[field] == value) {
          throw ApiException(
            message: 'menu_error_code_taken'.trParams({
              'code': '$value',
              'name': DemoNames.of(row),
            }),
            statusCode: 409,
          );
        }
      }
    }
    return patch;
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
