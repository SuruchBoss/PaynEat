import 'menu_option.dart';

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
