import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/domain/entities/menu_option.dart';

/// รายการในตะกร้าก่อนยืนยันส่งเข้าระบบ
///
/// อยู่ในชั้น domain เพราะเป็นกฎธุรกิจ (วิธีคิดราคาต่อบรรทัด)
/// ไม่ใช่แค่ state ของหน้าจอ
class CartLine {
  CartLine({
    required this.menuItem,
    this.quantity = 1,
    List<MenuOption>? selectedOptions,
    this.note,
  }) : selectedOptions = selectedOptions ?? <MenuOption>[];

  final MenuItem menuItem;
  int quantity;
  final List<MenuOption> selectedOptions;
  String? note;

  double get optionsPrice =>
      selectedOptions.fold(0, (sum, option) => sum + option.priceDelta);

  double get unitPrice => menuItem.price + optionsPrice;

  double get lineTotal => unitPrice * quantity;

  List<int> get optionIds =>
      selectedOptions.map((option) => option.id).toList(growable: false);

  String get optionsSummary =>
      selectedOptions.map((option) => option.name).join(' • ');

  /// ใช้รวมบรรทัดที่ "เมนูเดียวกัน ตัวเลือกเดียวกัน โน้ตเดียวกัน" เข้าด้วยกัน
  String get signature {
    final ids = [...optionIds]..sort();
    return '${menuItem.id}|${ids.join(',')}|${note ?? ''}';
  }

  CartLine copyWith({int? quantity, String? note}) => CartLine(
    menuItem: menuItem,
    quantity: quantity ?? this.quantity,
    selectedOptions: List<MenuOption>.from(selectedOptions),
    note: note ?? this.note,
  );
}
