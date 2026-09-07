import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_option.dart';

class MenuOptionModel extends MenuOption {
  const MenuOptionModel({
    required super.id,
    required super.name,
    super.priceDelta,
    super.isDefault,
  });

  factory MenuOptionModel.fromJson(Map<String, dynamic> json) =>
      MenuOptionModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        priceDelta: (json['priceDelta'] as num?)?.toDouble() ?? 0,
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

class MenuOptionGroupModel extends MenuOptionGroup {
  const MenuOptionGroupModel({
    required super.id,
    required super.name,
    required super.options,
    super.minSelect,
    super.maxSelect,
    super.isRequired,
  });

  factory MenuOptionGroupModel.fromJson(Map<String, dynamic> json) =>
      MenuOptionGroupModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        minSelect: (json['minSelect'] as num?)?.toInt() ?? 0,
        maxSelect: (json['maxSelect'] as num?)?.toInt() ?? 1,
        isRequired: json['isRequired'] as bool? ?? false,
        options: (json['options'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MenuOptionModel.fromJson)
            .toList(growable: false),
      );
}

class MenuItemModel extends MenuItem {
  const MenuItemModel({
    required super.id,
    required super.categoryId,
    required super.name,
    required super.price,
    super.categoryName,
    super.nameEn,
    super.description,
    super.imageUrl,
    super.isAvailable,
    super.isRecommended,
    super.prepMinutes,
    super.sortOrder,
    super.optionGroups,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) => MenuItemModel(
    id: (json['id'] as num).toInt(),
    categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
    categoryName: json['categoryName'] as String?,
    name: json['name'] as String? ?? '',
    nameEn: json['nameEn'] as String?,
    description: json['description'] as String?,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    imageUrl: json['imageUrl'] as String?,
    isAvailable: json['isAvailable'] as bool? ?? true,
    isRecommended: json['isRecommended'] as bool? ?? false,
    prepMinutes: (json['prepMinutes'] as num?)?.toInt() ?? 10,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    optionGroups: (json['optionGroups'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MenuOptionGroupModel.fromJson)
        .toList(growable: false),
  );
}

/// ข้อมูลที่ใช้สร้าง/แก้ไขเมนู (แยกจาก entity เพราะรูปร่างต่างกัน)
class MenuItemPayload {
  const MenuItemPayload({
    required this.name,
    required this.categoryId,
    required this.price,
    this.nameEn,
    this.description,
    this.imageUrl,
    this.isAvailable,
    this.isRecommended,
    this.prepMinutes,
    this.optionGroups,
  });

  final String name;
  final int categoryId;
  final double price;
  final String? nameEn;
  final String? description;
  final String? imageUrl;
  final bool? isAvailable;
  final bool? isRecommended;
  final int? prepMinutes;
  final List<MenuOptionGroup>? optionGroups;

  Map<String, dynamic> toJson() => {
    'name': name,
    'categoryId': categoryId,
    'price': price,
    if (nameEn != null && nameEn!.isNotEmpty) 'nameEn': nameEn,
    if (description != null && description!.isNotEmpty)
      'description': description,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (isAvailable != null) 'isAvailable': isAvailable,
    if (isRecommended != null) 'isRecommended': isRecommended,
    if (prepMinutes != null) 'prepMinutes': prepMinutes,
    if (optionGroups != null)
      'optionGroups': optionGroups!
          .map(
            (group) => {
              'name': group.name,
              'minSelect': group.minSelect,
              'maxSelect': group.maxSelect,
              'isRequired': group.isRequired,
              'options': group.options
                  .map(
                    (option) => {
                      'name': option.name,
                      'priceDelta': option.priceDelta,
                      'isDefault': option.isDefault,
                    },
                  )
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
  };
}
