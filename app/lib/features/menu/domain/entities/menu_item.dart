import '../../../../core/localization/locale_service.dart';
import '../../../ingredient/domain/entities/ingredient.dart';
import 'menu_option.dart';

/// เมนูอาหาร 1 รายการ
class MenuItem {
  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    this.categoryName,
    this.nameEn,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
    this.isRecommended = false,
    this.prepMinutes = 10,
    this.sortOrder = 0,
    this.optionGroups = const [],
    this.ingredients = const [],
  });

  final int id;
  final int categoryId;
  final String? categoryName;
  final String name;
  final String? nameEn;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final bool isRecommended;
  final int prepMinutes;
  final int sortOrder;
  final List<MenuOptionGroup> optionGroups;

  /// วัตถุดิบที่ผูกไว้ + ปริมาณที่ใช้ต่อ 1 ที่ — ระบบตัดสต๊อกอัตโนมัติเมื่อขาย
  /// (ดู docs/tickets/06-inventory-stock.md)
  final List<MenuItemIngredientUsage> ingredients;

  /// ชื่อที่จะแสดงตามภาษาปัจจุบัน — ถอยกลับไปใช้ [name] (ไทย) ถ้าไม่มี [nameEn]
  String get displayName =>
      LocaleService.isEnglish && (nameEn?.isNotEmpty ?? false) ? nameEn! : name;

  bool get hasOptions => optionGroups.isNotEmpty;

  /// ต้องเปิดหน้าเลือกตัวเลือกก่อนใส่ตะกร้าไหม
  bool get requiresSelection =>
      optionGroups.any((group) => group.isRequired || group.options.length > 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MenuItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
