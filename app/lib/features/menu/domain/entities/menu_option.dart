/// ตัวเลือกย่อยของเมนู เช่น "ไข่ดาว (+15)" หรือ "เผ็ดมาก"
class MenuOption {
  const MenuOption({
    required this.id,
    required this.name,
    this.priceDelta = 0,
    this.isDefault = false,
  });

  final int id;
  final String name;
  final double priceDelta;
  final bool isDefault;

  bool get hasExtraCharge => priceDelta > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MenuOption && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// กลุ่มของตัวเลือก เช่น "ระดับความเผ็ด" (เลือกได้ 1) หรือ "เพิ่มพิเศษ" (เลือกได้หลายอัน)
class MenuOptionGroup {
  const MenuOptionGroup({
    required this.id,
    required this.name,
    required this.options,
    this.minSelect = 0,
    this.maxSelect = 1,
    this.isRequired = false,
  });

  final int id;
  final String name;
  final List<MenuOption> options;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;

  bool get isSingleChoice => maxSelect == 1;

  /// ตัวเลือกที่ควรถูกเลือกไว้ให้ตั้งแต่แรก
  List<MenuOption> get defaults =>
      options.where((option) => option.isDefault).toList(growable: false);
}
