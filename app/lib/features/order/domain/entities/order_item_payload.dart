/// รูปแบบข้อมูลรายการอาหารที่ส่งขึ้น API
class OrderItemPayload {
  const OrderItemPayload({
    required this.menuItemId,
    required this.quantity,
    this.optionIds = const [],
    this.note,
  });

  final int menuItemId;
  final int quantity;
  final List<int> optionIds;
  final String? note;

  Map<String, dynamic> toJson() => {
    'menuItemId': menuItemId,
    'quantity': quantity,
    'optionIds': optionIds,
    if (note != null && note!.isNotEmpty) 'note': note,
  };
}
