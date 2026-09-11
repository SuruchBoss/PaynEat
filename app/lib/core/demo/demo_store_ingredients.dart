part of 'demo_store.dart';

// ------------------------------------------------------------ ingredients ------
extension DemoStoreIngredients on DemoStore {
  Map<String, dynamic> _rawIngredient(int id) => ingredients.firstWhere(
    (row) => row['id'] == id,
    orElse: () => throw ApiException(
      message: 'ingredient_error_not_found'.tr,
      statusCode: 404,
    ),
  );

  Map<String, dynamic> _withIsLowStock(Map<String, dynamic> row) => {
    ...row,
    'isLowStock':
        (row['currentStock'] as num) <= (row['lowStockThreshold'] as num),
  };

  List<Map<String, dynamic>> ingredientList({bool lowStockOnly = false}) {
    return ingredients
        .map(_withIsLowStock)
        .where((row) => !lowStockOnly || row['isLowStock'] == true)
        .toList(growable: false);
  }

  Map<String, dynamic> ingredient(int id) =>
      _withIsLowStock(_rawIngredient(id));

  Map<String, dynamic> saveIngredient(Map<String, dynamic> body, {int? id}) {
    if (id == null) {
      final ingredient = {
        'id': _nextId(),
        'name': body['name'],
        'unit': body['unit'],
        'currentStock': (body['currentStock'] as num?)?.toDouble() ?? 0,
        'lowStockThreshold':
            (body['lowStockThreshold'] as num?)?.toDouble() ?? 0,
      };
      ingredients.add(ingredient);
      return _withIsLowStock(ingredient);
    }

    final raw = _rawIngredient(id);
    if (body['name'] != null) raw['name'] = body['name'];
    if (body['unit'] != null) raw['unit'] = body['unit'];
    if (body['lowStockThreshold'] != null) {
      raw['lowStockThreshold'] = (body['lowStockThreshold'] as num).toDouble();
    }
    return _withIsLowStock(raw);
  }

  Map<String, dynamic> adjustIngredientStock(int id, double delta) {
    if (delta == 0) {
      throw ApiException(
        message: 'ingredient_error_zero_delta'.tr,
        statusCode: 422,
      );
    }
    final raw = _rawIngredient(id);
    raw['currentStock'] = (raw['currentStock'] as num).toDouble() + delta;
    _syncMenuItemAvailabilityForIngredients({id});
    return _withIsLowStock(raw);
  }

  void deleteIngredient(int id) {
    _rawIngredient(id);
    final linked = menuItems.any(
      (item) => (item['ingredients'] as List? ?? const []).any(
        (link) => link['ingredientId'] == id,
      ),
    );
    if (linked) {
      throw ApiException(
        message: 'ingredient_error_linked_cannot_delete'.tr,
        statusCode: 409,
      );
    }
    ingredients.removeWhere((row) => row['id'] == id);
  }

  /// เมนูที่ผูกกับวัตถุดิบใดใน [ingredientIds] — เช็คว่ายัง "สั่งได้" อยู่ไหม
  /// (ต้องมีสต๊อกพอ >= qtyPerUnit ครบทุกวัตถุดิบที่ผูกไว้) แล้วเปิด/ปิดขายอัตโนมัติตามนั้น
  /// ปิดขายเองจะไม่ถูกเปิดกลับให้ — เปิดกลับให้เฉพาะเมนูที่ระบบนี้เป็นคนปิดไว้เท่านั้น
  /// (mirror ของ backend: ingredient.service.js#syncMenuItemAvailabilityForIngredients)
  void _syncMenuItemAvailabilityForIngredients(Set<int> ingredientIds) {
    for (final menu in menuItems) {
      final links = (menu['ingredients'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      if (links.isEmpty) continue;
      final touchesChangedIngredient = links.any(
        (link) => ingredientIds.contains(link['ingredientId']),
      );
      if (!touchesChangedIngredient) continue;

      final isOrderable = links.every((link) {
        final raw = _rawIngredient(link['ingredientId'] as int);
        return (raw['currentStock'] as num).toDouble() >=
            (link['qtyPerUnit'] as num).toDouble();
      });

      if (!isOrderable && menu['isAvailable'] == true) {
        menu['isAvailable'] = false;
        menu['autoDisabledByStock'] = true;
      } else if (isOrderable &&
          menu['isAvailable'] != true &&
          menu['autoDisabledByStock'] == true) {
        menu['isAvailable'] = true;
        menu['autoDisabledByStock'] = false;
      }
    }
  }

  /// หัก/คืนสต๊อกของวัตถุดิบที่ผูกกับเมนูของ order item นี้ ตาม factor × qtyPerUnit × quantity
  void _applyIngredientDelta(Map<String, dynamic> item, double factor) {
    final menu = menuItems.firstWhere(
      (row) => row['id'] == item['menuItemId'],
      orElse: () => const {},
    );
    final links = (menu['ingredients'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    if (links.isEmpty) return;

    final quantity = (item['quantity'] as num).toDouble();
    for (final link in links) {
      final ingredientId = link['ingredientId'] as int;
      final qtyPerUnit = (link['qtyPerUnit'] as num).toDouble();
      final raw = _rawIngredient(ingredientId);
      raw['currentStock'] =
          (raw['currentStock'] as num).toDouble() +
          factor * qtyPerUnit * quantity;
    }
    _syncMenuItemAvailabilityForIngredients(
      links.map((link) => link['ingredientId'] as int).toSet(),
    );
  }

  /// ตัดสต๊อกตอนรายการอาหารถูกส่งครัว (หรือถูกเพิ่มเข้าออเดอร์ที่ส่งครัวไปแล้ว)
  void deductForOrderItem(Map<String, dynamic> item) =>
      _applyIngredientDelta(item, -1);

  /// คืนสต๊อกตอนยกเลิก/ลบรายการอาหารที่เคยตัดสต๊อกไปแล้ว
  void restoreForOrderItem(Map<String, dynamic> item) =>
      _applyIngredientDelta(item, 1);

  /// ปรับสต๊อกตามส่วนต่างจำนวนที่แก้ไข — ใช้เฉพาะรายการที่ตัดสต๊อกไปแล้วเท่านั้น
  void adjustIngredientsForQuantityChange(
    Map<String, dynamic> item,
    int oldQuantity,
    int newQuantity,
  ) {
    if (oldQuantity == newQuantity) return;
    final deltaQty = (newQuantity - oldQuantity).toDouble();
    _applyIngredientDelta({...item, 'quantity': deltaQty}, -1);
  }
}
