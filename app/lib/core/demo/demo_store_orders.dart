part of 'demo_store.dart';

// ----------------------------------------------------------- orders -----
extension DemoStoreOrders on DemoStore {
  Map<String, dynamic> findOrder(int id) => orders.firstWhere(
    (row) => row['id'] == id,
    orElse: () =>
        throw const ApiException(message: 'ไม่พบออเดอร์นี้', statusCode: 404),
  );

  List<Map<String, dynamic>> orderList({
    String? status,
    bool? activeOnly,
    String? dateFrom,
  }) {
    final result = orders.where((order) {
      if (status != null && order['status'] != status) return false;
      if (activeOnly == true &&
          !OrderStatus.isActive(order['status'] as String)) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
    return result;
  }

  Map<String, dynamic>? openOrderByTable(int tableId) {
    for (final order in orders) {
      if (order['tableId'] == tableId &&
          OrderStatus.isActive(order['status'] as String)) {
        return order;
      }
    }
    return null;
  }

  Map<String, dynamic> createOrder({
    required String type,
    int? tableId,
    required int guestCount,
    required List<Map<String, dynamic>> items,
    int? waiterId,
  }) {
    if (tableId != null && openOrderByTable(tableId) != null) {
      throw const ApiException(
        message: 'โต๊ะนี้มีออเดอร์ที่เปิดอยู่แล้ว',
        statusCode: 409,
      );
    }

    final table = tableId == null ? null : _findTable(tableId);
    final now = DateTime.now();
    final code =
        'ORD-${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '-${(++_orderSequence).toString().padLeft(4, '0')}';

    final order = <String, dynamic>{
      'id': _nextId(),
      'code': code,
      'type': type,
      'tableId': tableId,
      'tableName': table?['name'],
      'tableZone': table?['zone'],
      'waiterId': waiterId,
      'waiterName': waiterId == null ? null : _findUser(waiterId)['name'],
      'guestCount': guestCount,
      'status': OrderStatus.open,
      'note': null,
      'subtotal': 0.0,
      'discountType': DiscountType.none,
      'discountValue': 0.0,
      'discountAmount': 0.0,
      'serviceCharge': 0.0,
      'vat': 0.0,
      'total': 0.0,
      'cancelledReason': null,
      'createdAt': _now(),
      'updatedAt': _now(),
      'closedAt': null,
      'items': <Map<String, dynamic>>[],
    };

    orders.add(order);
    _appendItems(order, items);
    if (table != null) table['status'] = TableStatus.occupied;

    return _recalculate(order);
  }

  Map<String, dynamic> addItems(int orderId, List<Map<String, dynamic>> items) {
    final order = findOrder(orderId);
    _assertMutable(order);
    _appendItems(order, items);
    return _recalculate(order);
  }

  void _appendItems(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> inputs,
  ) {
    final items = order['items'] as List;

    for (final input in inputs) {
      final menu = menuItem(input['menuItemId'] as int);
      if (menu['isAvailable'] != true) {
        throw ApiException(
          message: 'เมนู "${menu['name']}" ปิดการขายอยู่',
          statusCode: 409,
        );
      }

      final selected = <Map<String, dynamic>>[];
      for (final optionId in (input['optionIds'] as List? ?? const [])) {
        for (final group in (menu['optionGroups'] as List)) {
          for (final option in (group['options'] as List)) {
            if (option['id'] == optionId) {
              selected.add({
                'id': option['id'],
                'groupName': group['name'],
                'name': option['name'],
                'priceDelta': option['priceDelta'],
              });
            }
          }
        }
      }

      final optionsPrice = selected.fold<double>(
        0,
        (sum, option) => sum + (option['priceDelta'] as num).toDouble(),
      );
      final unitPrice = (menu['price'] as num).toDouble();
      final quantity = input['quantity'] as int;

      items.add({
        'id': _nextId(),
        'orderId': order['id'],
        'menuItemId': menu['id'],
        'name': menu['name'],
        'unitPrice': unitPrice,
        'quantity': quantity,
        'options': selected,
        'optionsPrice': optionsPrice,
        'lineTotal': (unitPrice + optionsPrice) * quantity,
        'note': input['note'],
        'status': OrderItemStatus.pending,
        'isPaid': false,
        'createdAt': _now(),
        'updatedAt': _now(),
        'orderCode': order['code'],
        'tableName': order['tableName'],
        'orderType': order['type'],
      });
    }
  }

  Map<String, dynamic> updateItem(
    int orderId,
    int itemId, {
    int? quantity,
    String? note,
  }) {
    final order = findOrder(orderId);
    _assertMutable(order);
    final item = _findItem(order, itemId);

    if (item['status'] != OrderItemStatus.pending) {
      throw const ApiException(
        message: 'แก้ไขไม่ได้ เพราะครัวเริ่มทำรายการนี้แล้ว',
        statusCode: 409,
      );
    }

    if (quantity != null) {
      item['quantity'] = quantity;
      item['lineTotal'] =
          ((item['unitPrice'] as num) + (item['optionsPrice'] as num))
              .toDouble() *
          quantity;
    }
    if (note != null) item['note'] = note;

    return _recalculate(order);
  }

  Map<String, dynamic> removeItem(int orderId, int itemId) {
    final order = findOrder(orderId);
    _assertMutable(order);
    final item = _findItem(order, itemId);

    if (item['status'] != OrderItemStatus.pending) {
      throw const ApiException(
        message:
            'ลบไม่ได้ เพราะครัวเริ่มทำรายการนี้แล้ว กรุณาใช้การยกเลิกรายการแทน',
        statusCode: 409,
      );
    }

    (order['items'] as List).removeWhere((row) => row['id'] == itemId);
    return _recalculate(order);
  }

  Map<String, dynamic> updateItemStatus(
    int orderId,
    int itemId,
    String status,
  ) {
    final order = findOrder(orderId);
    final item = _findItem(order, itemId);

    const transitions = {
      OrderItemStatus.pending: [
        OrderItemStatus.cooking,
        OrderItemStatus.ready,
        OrderItemStatus.cancelled,
      ],
      OrderItemStatus.cooking: [
        OrderItemStatus.ready,
        OrderItemStatus.cancelled,
      ],
      OrderItemStatus.ready: [
        OrderItemStatus.served,
        OrderItemStatus.cancelled,
      ],
      OrderItemStatus.served: <String>[],
      OrderItemStatus.cancelled: <String>[],
    };

    final allowed = transitions[item['status']] ?? const <String>[];
    if (!allowed.contains(status)) {
      throw ApiException(
        message: 'เปลี่ยนสถานะจาก "${item['status']}" เป็น "$status" ไม่ได้',
        statusCode: 409,
      );
    }

    item['status'] = status;
    item['updatedAt'] = _now();

    final active = (order['items'] as List)
        .where((row) => row['status'] != OrderItemStatus.cancelled)
        .toList();
    if (active.isNotEmpty &&
        active.every((row) => row['status'] == OrderItemStatus.served) &&
        order['status'] == OrderStatus.inKitchen) {
      order['status'] = OrderStatus.served;
    }

    return _recalculate(order);
  }

  Map<String, dynamic> sendToKitchen(int orderId) {
    final order = findOrder(orderId);
    _assertMutable(order);

    final active = (order['items'] as List).where(
      (row) => row['status'] != OrderItemStatus.cancelled,
    );
    if (active.isEmpty) {
      throw const ApiException(
        message: 'ออเดอร์ยังไม่มีรายการอาหาร',
        statusCode: 400,
      );
    }

    if (order['status'] == OrderStatus.open) {
      order['status'] = OrderStatus.inKitchen;
    }
    return _recalculate(order);
  }

  Map<String, dynamic> applyDiscount(int orderId, String type, double value) {
    final order = findOrder(orderId);
    _assertMutable(order);
    order['discountType'] = type;
    order['discountValue'] = type == DiscountType.none ? 0.0 : value;
    return _recalculate(order);
  }

  /// ย้ายออเดอร์ (ที่ยังไม่ปิดบิล) ไปโต๊ะอื่น เช่น ลูกค้าขอย้ายที่นั่ง
  Map<String, dynamic> moveOrderTable(int orderId, int tableId) {
    final order = findOrder(orderId);
    _assertMutable(order);
    final oldTableId = order['tableId'];
    if (oldTableId == null) {
      throw const ApiException(
        message: 'ออเดอร์นี้ไม่ได้ผูกกับโต๊ะ ย้ายโต๊ะไม่ได้',
        statusCode: 400,
      );
    }
    if (oldTableId == tableId) {
      throw const ApiException(
        message: 'เลือกโต๊ะเดิม ไม่ต้องย้าย',
        statusCode: 400,
      );
    }
    if (openOrderByTable(tableId) != null) {
      throw const ApiException(
        message: 'โต๊ะปลายทางมีออเดอร์ที่เปิดอยู่แล้ว',
        statusCode: 409,
      );
    }

    final table = _findTable(tableId);
    order['tableId'] = tableId;
    order['tableName'] = table['name'];
    order['tableZone'] = table['zone'];
    table['status'] = TableStatus.occupied;
    _findTable(oldTableId as int)['status'] = TableStatus.available;
    order['updatedAt'] = _now();

    for (final item in (order['items'] as List).cast<Map<String, dynamic>>()) {
      item['tableName'] = table['name'];
    }

    return order;
  }

  /// รวมออเดอร์ต้นทางเข้ากับออเดอร์ปลายทาง — ใช้ตอนลูกค้าขอรวมโต๊ะ/รวมบิล
  Map<String, dynamic> mergeOrders(int targetOrderId, int sourceOrderId) {
    if (targetOrderId == sourceOrderId) {
      throw const ApiException(
        message: 'เลือกออเดอร์ปลายทางเดียวกับต้นทางไม่ได้',
        statusCode: 400,
      );
    }
    final target = findOrder(targetOrderId);
    final source = findOrder(sourceOrderId);
    _assertMutable(target);
    _assertMutable(source);

    final sourceItems = (source['items'] as List).cast<Map<String, dynamic>>();
    final targetItems = target['items'] as List;
    for (final item in sourceItems) {
      item['orderId'] = target['id'];
      item['orderCode'] = target['code'];
      item['tableName'] = target['tableName'];
      item['orderType'] = target['type'];
      targetItems.add(item);
    }
    sourceItems.clear();

    source['status'] = OrderStatus.cancelled;
    source['cancelledReason'] = 'รวมเข้ากับบิล #${target['code']}';
    source['closedAt'] = _now();
    _freeTable(source);

    return _recalculate(target);
  }

  Map<String, dynamic> cancelOrder(int orderId, String reason) {
    final order = findOrder(orderId);
    if (order['status'] == OrderStatus.paid) {
      throw const ApiException(
        message: 'ออเดอร์ที่ชำระแล้วยกเลิกไม่ได้',
        statusCode: 409,
      );
    }

    for (final item in (order['items'] as List)) {
      if (item['status'] != OrderItemStatus.served) {
        item['status'] = OrderItemStatus.cancelled;
      }
    }
    order['status'] = OrderStatus.cancelled;
    order['cancelledReason'] = reason;
    order['closedAt'] = _now();
    _freeTable(order);

    return _recalculate(order);
  }

  List<Map<String, dynamic>> kitchenQueue(List<String> statuses) {
    final result = <Map<String, dynamic>>[];
    for (final order in orders) {
      final status = order['status'] as String;
      if (status != OrderStatus.inKitchen && status != OrderStatus.served) {
        continue;
      }
      for (final item
          in (order['items'] as List).cast<Map<String, dynamic>>()) {
        if (statuses.contains(item['status'])) {
          result.add({
            ...item,
            'tableName': order['tableName'],
            'orderCode': order['code'],
          });
        }
      }
    }
    result.sort(
      (a, b) => (a['createdAt'] as String).compareTo(b['createdAt'] as String),
    );
    return result;
  }

  Map<String, dynamic> _findItem(Map<String, dynamic> order, int itemId) =>
      (order['items'] as List).cast<Map<String, dynamic>>().firstWhere(
        (row) => row['id'] == itemId,
        orElse: () => throw const ApiException(
          message: 'ไม่พบรายการนี้ในออเดอร์',
          statusCode: 404,
        ),
      );

  void _assertMutable(Map<String, dynamic> order) {
    if (!OrderStatus.isActive(order['status'] as String)) {
      throw const ApiException(
        message: 'ออเดอร์นี้ปิดแล้ว ไม่สามารถแก้ไขได้',
        statusCode: 409,
      );
    }
  }

  void _freeTable(Map<String, dynamic> order) {
    final tableId = order['tableId'];
    if (tableId is int) {
      _findTable(tableId)['status'] = TableStatus.available;
    }
  }

  /// คิดยอดใหม่ทั้งบิลด้วยกฎเดียวกับ backend
  Map<String, dynamic> _recalculate(Map<String, dynamic> order) {
    final subtotal = (order['items'] as List)
        .where((item) => item['status'] != OrderItemStatus.cancelled)
        .fold<double>(
          0,
          (sum, item) => sum + (item['lineTotal'] as num).toDouble(),
        );

    final type = order['discountType'] as String;
    final value = (order['discountValue'] as num).toDouble();

    final bill = _calculator.fromSubtotal(
      subtotal,
      discountAmount: type == DiscountType.amount ? value : 0,
      discountPercent: type == DiscountType.percent ? value : 0,
    );

    order['subtotal'] = bill.subtotal;
    order['discountAmount'] = bill.discount;
    order['serviceCharge'] = bill.serviceCharge;
    order['vat'] = bill.vat;
    order['total'] = bill.total;
    order['updatedAt'] = _now();

    return order;
  }
}
