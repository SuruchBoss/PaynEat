import '../../../../core/localization/locale_service.dart';
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
