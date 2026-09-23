part of 'demo_data_sources.dart';

/// mirror ของ public-order.service.js ฝั่ง backend (ดู docs/tickets/17-qr-self-order.md) — ไม่มี
/// currentUserId/actorId ผูกอยู่เลยตลอดทั้งไฟล์นี้โดยตั้งใจ เพราะลูกค้าไม่ได้ login เหมือนกันทั้งคู่
class DemoSelfOrderDataSource implements SelfOrderRemoteDataSource {
  const DemoSelfOrderDataSource(this._store);

  final DemoStore _store;

  @override
  Future<({SelfOrderTableModel table, OrderModel? order})> getTable(
    String qrToken,
  ) => _delayed(() {
    final table = _store.resolveTableByQrToken(qrToken);
    final order = _store.openOrderByTable(table['id'] as int);
    return (
      // โหมดสาธิตมีสาขาเดียวเสมอ (ดู docs/DECISIONS.md #36) จึงไม่มี branchName ให้โชว์
      table: SelfOrderTableModel.fromJson(table),
      order: order == null ? null : OrderModel.fromJson(order),
    );
  });

  @override
  Future<({List<CategoryModel> categories, List<MenuItemModel> items})> getMenu(
    String qrToken,
  ) => _delayed(() {
    _store.resolveTableByQrToken(qrToken);
    return (
      categories: _store
          .categoryList()
          .map(CategoryModel.fromJson)
          .toList(growable: false),
      items: _store
          .menuList(availableOnly: true)
          .map(MenuItemModel.fromJson)
          .toList(growable: false),
    );
  });

  @override
  Future<OrderModel> addItems(
    String qrToken,
    List<OrderItemPayload> items,
  ) => _delayed(() {
    final table = _store.resolveTableByQrToken(qrToken);
    final tableId = table['id'] as int;
    final itemsJson = items
        .map((item) => item.toJson())
        .toList(growable: false);

    final existing = _store.openOrderByTable(tableId);
    final order = existing == null
        ? _store.createOrder(
            type: OrderType.dineIn,
            tableId: tableId,
            guestCount: 1,
            items: itemsJson,
          )
        : _store.addItems(existing['id'] as int, itemsJson);
    // mirror ของ public-order.service.js#addItems — ลูกค้ากด "ส่งเข้าครัว" ร่างออเดอร์จึงต้อง
    // เข้าครัวจริง ไม่งั้นครัวไม่เห็น (DECISIONS #46)
    final sent = order['status'] == OrderStatus.open
        ? _store.sendToKitchen(order['id'] as int)
        : order;
    return OrderModel.fromJson(sent);
  });
}
