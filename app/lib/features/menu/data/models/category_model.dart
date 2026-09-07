import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    super.nameEn,
    super.icon,
    super.sortOrder,
    super.isActive,
    super.itemCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        nameEn: json['nameEn'] as String?,
        icon: json['icon'] as String?,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      );

  static Map<String, dynamic> toCreateJson({
    required String name,
    String? nameEn,
    String? icon,
    int? sortOrder,
  }) =>
      {
        'name': name,
        if (nameEn != null && nameEn.isNotEmpty) 'nameEn': nameEn,
        if (icon != null && icon.isNotEmpty) 'icon': icon,
        if (sortOrder != null) 'sortOrder': sortOrder,
      };
}
