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

  /// ย้อนกลับจาก JSON — ใช้ตอนอ่านคิวออฟไลน์ที่เก็บไว้ใน local storage กลับมา
  factory OrderItemPayload.fromJson(Map<String, dynamic> json) =>
      OrderItemPayload(
        menuItemId: json['menuItemId'] as int,
        quantity: json['quantity'] as int,
        optionIds: (json['optionIds'] as List? ?? const [])
            .map((id) => id as int)
            .toList(growable: false),
        note: json['note'] as String?,
      );
}
