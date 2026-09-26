// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

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
    this.weightGrams,
  }) : selectedOptions = selectedOptions ?? <MenuOption>[];

  final MenuItem menuItem;
  int quantity;
  final List<MenuOption> selectedOptions;
  String? note;

  /// น้ำหนักที่ชั่งได้ (กรัม) ของสินค้าขายตามน้ำหนัก — null = ขายเป็นชิ้น
  int? weightGrams;

  bool get isWeighed => weightGrams != null;

  double get optionsPrice =>
      selectedOptions.fold(0, (sum, option) => sum + option.priceDelta);

  double get unitPrice => menuItem.price + optionsPrice;

  /// ราคาบรรทัด — สินค้าชั่งน้ำหนักคิดเป็นสตางค์เต็มก่อนแล้วค่อยปัด ให้ตรงกับ backend
  /// ทุกสตางค์ (order.calculator.js#lineTotalFor): ถ้าคูณเป็นบาททศนิยมตรง ๆ 123.45 × 0.333
  /// จะได้ 41.10885 แต่ 123.45 × 100 ในเลขทศนิยมของเครื่องคือ 12344.999… ปัดผิดทางได้
  /// (ดู docs/DECISIONS.md #48)
  double get lineTotal {
    final grams = weightGrams;
    if (grams == null) return unitPrice * quantity;
    final perKgSatang =
        (menuItem.price * 100).round() +
        selectedOptions.fold<int>(
          0,
          (sum, option) => sum + (option.priceDelta * 100).round(),
        );
    return (perKgSatang * grams / 1000).round() / 100;
  }

  List<int> get optionIds =>
      selectedOptions.map((option) => option.id).toList(growable: false);

  String get optionsSummary =>
      selectedOptions.map((option) => option.name).join(' • ');

  /// ใช้รวมบรรทัดที่ "เมนูเดียวกัน ตัวเลือกเดียวกัน โน้ตเดียวกัน" เข้าด้วยกัน
  ///
  /// สินค้าชั่งน้ำหนักไม่รวมกันเลยแม้หนักเท่ากัน — ชั่งทีละถุง ฉลากหนึ่งใบคือหนึ่งบรรทัด
  /// (backend รับสินค้าชั่งน้ำหนักได้บรรทัดละ 1 ถุงเท่านั้น)
  String get signature {
    if (isWeighed) return 'weighed#${identityHashCode(this)}';
    final ids = [...optionIds]..sort();
    return '${menuItem.id}|${ids.join(',')}|${note ?? ''}';
  }

  CartLine copyWith({int? quantity, String? note, int? weightGrams}) =>
      CartLine(
        menuItem: menuItem,
        quantity: quantity ?? this.quantity,
        selectedOptions: List<MenuOption>.from(selectedOptions),
        note: note ?? this.note,
        weightGrams: weightGrams ?? this.weightGrams,
      );
}
