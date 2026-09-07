/// หมวดหมู่อาหาร เช่น อาหารจานเดียว / เครื่องดื่ม
class Category {
  const Category({
    required this.id,
    required this.name,
    this.nameEn,
    this.icon,
    this.sortOrder = 0,
    this.isActive = true,
    this.itemCount = 0,
  });

  final int id;
  final String name;
  final String? nameEn;
  final String? icon;
  final int sortOrder;
  final bool isActive;
  final int itemCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Category && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
