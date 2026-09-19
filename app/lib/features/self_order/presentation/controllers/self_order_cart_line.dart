import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/domain/entities/menu_option.dart';
import '../../../order/domain/entities/order_item_payload.dart';

/// รายการที่ลูกค้ากดเลือกไว้แต่ยังไม่ได้กด "ส่งเข้าครัว" (อยู่ในเครื่องเท่านั้น ยังไม่ถึง backend)
/// ดู docs/tickets/17-qr-self-order.md
class SelfOrderCartLine {
  const SelfOrderCartLine({
    required this.item,
    required this.quantity,
    this.options = const [],
    this.note,
  });

  final MenuItem item;
  final int quantity;
  final List<MenuOption> options;
  final String? note;

  double get optionsPrice =>
      options.fold(0.0, (sum, option) => sum + option.priceDelta);

  double get lineTotal => (item.price + optionsPrice) * quantity;

  OrderItemPayload toPayload() => OrderItemPayload(
    menuItemId: item.id,
    quantity: quantity,
    optionIds: options.map((option) => option.id).toList(growable: false),
    note: note,
  );
}
