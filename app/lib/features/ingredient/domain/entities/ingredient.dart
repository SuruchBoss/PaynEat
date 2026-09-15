/// วัตถุดิบ/สต๊อก (ดู docs/tickets/06-inventory-stock.md) — หน่วยนับ (unit) เป็น string
/// อิสระที่ร้านตั้งเอง เช่น "กก.", "ลิตร", "ชิ้น" ไม่มี unit conversion ข้ามหน่วย
class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    this.currentStock = 0,
    this.lowStockThreshold = 0,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String unit;
  final double currentStock;
  final double lowStockThreshold;
  final String? createdAt;
  final String? updatedAt;

  bool get isLowStock => currentStock <= lowStockThreshold;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ingredient && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// วัตถุดิบ 1 ตัวที่ผูกไว้กับเมนู + ปริมาณที่ใช้ต่อ 1 ที่ (qtyPerUnit)
class MenuItemIngredientUsage {
  const MenuItemIngredientUsage({
    required this.ingredientId,
    required this.qtyPerUnit,
    this.ingredientName,
    this.unit,
  });

  final int ingredientId;
  final double qtyPerUnit;
  final String? ingredientName;
  final String? unit;
}
