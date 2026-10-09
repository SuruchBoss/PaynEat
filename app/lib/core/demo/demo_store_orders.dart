// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

part of 'demo_store.dart';

// ----------------------------------------------------------- orders -----
extension DemoStoreOrders on DemoStore {
  Map<String, dynamic> findOrder(int id) => orders.firstWhere(
    (row) => row['id'] == id,
    orElse: () => throw ApiException(
      message: 'order_error_not_found'.tr,
      statusCode: 404,
    ),
  );

  List<Map<String, dynamic>> orderList({
    String? status,
    bool? activeOnly,
    String? dateFrom,
    int? customerId,
  }) {
    final result = orders.where((order) {
      if (status != null && order['status'] != status) return false;
      if (activeOnly == true &&
          !OrderStatus.isActive(order['status'] as String)) {
        return false;
      }
      if (customerId != null && order['customerId'] != customerId) {
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

  /// เลขคิวรับอาหาร รันต่อวันเฉพาะออเดอร์ type=takeaway — mirror ของ
  /// order.repository.js#nextQueueNumber (ดู docs/tickets/10-takeaway-delivery-flow.md)
  int _nextQueueNumber(DateTime now) {
    final sameDayTakeawayCount = orders.where((order) {
      if (order['type'] != OrderType.takeaway) return false;
      final createdAt = DateTime.tryParse(order['createdAt'] as String? ?? '');
      if (createdAt == null) return false;
      return createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).length;
    return sameDayTakeawayCount + 1;
  }

  Map<String, dynamic> createOrder({
    required String type,
    int? tableId,
    int? customerId,
    required int guestCount,
    required List<Map<String, dynamic>> items,
    int? waiterId,
  }) {
    if (tableId != null && openOrderByTable(tableId) != null) {
      throw ApiException(
        message: 'order_error_table_has_open_order'.tr,
        statusCode: 409,
      );
    }
    // ผูกลูกค้าแบบ optional (ดู docs/tickets/09-customer-loyalty.md)
    final customer = customerId == null ? null : findCustomer(customerId);

    final table = tableId == null ? null : _findTable(tableId);
    final now = AppClock.now();
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
      'tableZone': table == null ? null : DemoNames.of(table, key: 'zone'),
      'queueNumber': type == OrderType.takeaway ? _nextQueueNumber(now) : null,
      'waiterId': waiterId,
      'waiterName': waiterId == null ? null : DemoNames.of(_findUser(waiterId)),
      'customerId': customerId,
      'customerName': customer?['name'],
      'customerPhone': customer?['phone'],
      'pointsEarned': 0,
      'guestCount': guestCount,
      'status': OrderStatus.open,
      'note': null,
      'subtotal': 0.0,
      'discountType': DiscountType.none,
      'discountValue': 0.0,
      'discountAmount': 0.0,
      'promotionId': null,
      'promotionName': null,
      'promotionCode': null,
      'promotionDiscountAmount': 0.0,
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

    // mirror ของ order.service.js#create — log ทุกครั้งที่เปิดออเดอร์ใหม่ ดู
    // docs/tickets/13-order-audit-trail.md
    _logAudit(
      actorId: waiterId,
      action: 'order.create',
      summaryArgs: {'code': order['code'], 'count': items.length},
      entityType: 'order',
      entityId: order['id'] as int,
      summary: 'เปิดออเดอร์ใหม่ #${order['code']} (${items.length} รายการ)',
      metadata: {
        'orderCode': order['code'],
        'type': type,
        'tableId': tableId,
        'itemCount': items.length,
      },
    );

    return _recalculate(order);
  }

  Map<String, dynamic> sendToKitchen(int orderId) {
    final order = findOrder(orderId);
    _assertMutable(order);

    final active = (order['items'] as List)
        .where((row) => row['status'] != OrderItemStatus.cancelled)
        .cast<Map<String, dynamic>>()
        .toList();
    if (active.isEmpty) {
      throw ApiException(message: 'order_error_no_items'.tr, statusCode: 400);
    }

    if (order['status'] == OrderStatus.open) {
      order['status'] = OrderStatus.inKitchen;
    }

    // ตัดสต๊อกให้ทุกรายการที่ยังไม่เคยตัด (idempotent — กดส่งครัวซ้ำไม่ตัดซ้ำ)
    for (final item in active) {
      if (item['stockDeducted'] != true) {
        deductForOrderItem(item);
        item['stockDeducted'] = true;
      }
    }

    return _recalculate(order);
  }

  Map<String, dynamic> applyDiscount(
    int orderId,
    String type,
    double value, {
    int? actorId,
  }) {
    final order = findOrder(orderId);
    _assertMutable(order);
    final previousType = order['discountType'];
    final previousValue = order['discountValue'];
    order['discountType'] = type;
    order['discountValue'] = type == DiscountType.none ? 0.0 : value;

    // mirror ของ order.service.js#applyDiscount — log ทุกครั้งที่แก้ส่วนลด
    // รวมถึงตอนยกเลิกส่วนลด (type == none) ดู docs/tickets/08-audit-log.md
    _logAudit(
      actorId: actorId,
      action: 'order.discount',
      summaryArgs: {'code': order['code'], 'type': type, 'value': value},
      entityType: 'order',
      entityId: order['id'] as int,
      summary: type == DiscountType.none
          ? 'ยกเลิกส่วนลดออเดอร์ #${order['code']}'
          : 'ให้ส่วนลดออเดอร์ #${order['code']} เป็น ${_jsNumber(value)}'
                '${type == DiscountType.percent ? '%' : ' บาท'}',
      metadata: {
        'orderCode': order['code'],
        'previousType': previousType,
        'previousValue': previousValue,
        'newType': type,
        'newValue': order['discountValue'],
      },
    );

    return _recalculate(order);
  }

  /// ย้ายออเดอร์ (ที่ยังไม่ปิดบิล) ไปโต๊ะอื่น เช่น ลูกค้าขอย้ายที่นั่ง
  Map<String, dynamic> moveOrderTable(
    int orderId,
    int tableId, {
    int? actorId,
  }) {
    final order = findOrder(orderId);
    _assertMutable(order);
    final oldTableId = order['tableId'];
    if (oldTableId == null) {
      throw ApiException(message: 'order_error_no_table'.tr, statusCode: 400);
    }
    if (oldTableId == tableId) {
      throw ApiException(message: 'order_error_same_table'.tr, statusCode: 400);
    }
    if (openOrderByTable(tableId) != null) {
      throw ApiException(
        message: 'order_error_destination_table_occupied'.tr,
        statusCode: 409,
      );
    }

    final oldTableName = order['tableName'];
    final table = _findTable(tableId);
    order['tableId'] = tableId;
    order['tableName'] = table['name'];
    order['tableZone'] = DemoNames.of(table, key: 'zone');
    table['status'] = TableStatus.occupied;
    _findTable(oldTableId as int)['status'] = TableStatus.available;
    order['updatedAt'] = _now();

    for (final item in (order['items'] as List).cast<Map<String, dynamic>>()) {
      item['tableName'] = table['name'];
    }

    // mirror ของ order.service.js#moveTable — ดู docs/tickets/13-order-audit-trail.md
    _logAudit(
      actorId: actorId,
      action: 'order.move_table',
      summaryArgs: {
        'code': order['code'],
        'fromTable': oldTableName,
        'toTable': table['name'],
      },
      entityType: 'order',
      entityId: orderId,
      summary:
          'ย้ายออเดอร์ #${order['code']} จากโต๊ะ "$oldTableName" '
          'ไปโต๊ะ "${table['name']}"',
      metadata: {
        'orderCode': order['code'],
        'fromTableId': oldTableId,
        'toTableId': tableId,
      },
    );

    return order;
  }

  /// รวมออเดอร์ต้นทางเข้ากับออเดอร์ปลายทาง — ใช้ตอนลูกค้าขอรวมโต๊ะ/รวมบิล
  /// แผนรวมบิล — mirror ของ `planMerge` ใน order.service.js (T09 #96, docs/DECISIONS.md #77 D3, #98) ใช้ทั้งตอนดูตัวอย่าง
  /// และตอนรวมจริง: ยอดที่จ่ายแล้วกับส่วนลดที่กรอกเองย้ายตามไปที่ปลายทาง (ส่วนลดต้นทางกลายเป็นยอดบาท) โปรโมชันประเมินใหม่
  /// (โค้ดของปลายทาง > โค้ดของต้นทาง > โปรอัตโนมัติ) และการชำระที่ผูกกับลูกค้าย้ายไปบิลของลูกค้าคนอื่นไม่ได้
  ({
    String discountType,
    double discountValue,
    Map<String, dynamic> owner,
    Map<String, dynamic> merged,
  })
  _planMerge(Map<String, dynamic> target, Map<String, dynamic> source) {
    if (target['id'] == source['id']) {
      throw ApiException(
        message: 'order_error_merge_same_order'.tr,
        statusCode: 400,
      );
    }
    _assertMutable(target);
    _assertMutable(source);
    final customerBound = payments.any(
      (row) =>
          row['orderId'] == source['id'] &&
          (row['method'] == PaymentMethod.credit ||
              ((row['pointsRedeemed'] as num?) ?? 0) > 0),
    );
    if (customerBound && source['customerId'] != target['customerId']) {
      throw ApiException(
        message: 'order_error_merge_customer_mismatch'.trParams({
          'code': source['code'] as String,
        }),
        statusCode: 409,
        code: 'MERGE_CUSTOMER_MISMATCH',
      );
    }

    final sourceDiscount = (source['discountAmount'] as num).toDouble();
    final discountType = sourceDiscount > 0
        ? DiscountType.amount
        : target['discountType'] as String;
    final discountValue = sourceDiscount > 0
        ? (target['discountAmount'] as num).toDouble() + sourceDiscount
        : (target['discountValue'] as num).toDouble();
    final owner =
        target['promotionCode'] == null && source['promotionCode'] != null
        ? source
        : target;
    final merged = _recalculate({
      ...target,
      'items': [...(target['items'] as List), ...(source['items'] as List)],
      'discountType': discountType,
      'discountValue': discountValue,
      'promotionId': owner['promotionId'],
      'promotionName': owner['promotionName'],
      'promotionCode': owner['promotionCode'],
    }, settle: false);
    return (
      discountType: discountType,
      discountValue: discountValue,
      owner: owner,
      merged: merged,
    );
  }

  /// ดูผลของการรวมบิลก่อนยืนยัน — mirror ของ order.service.js#previewMerge
  Map<String, dynamic> previewMerge(int targetOrderId, int sourceOrderId) {
    final target = findOrder(targetOrderId);
    final source = findOrder(sourceOrderId);
    final plan = _planMerge(target, source);
    int cents(Object? baht) => ((baht as num) * 100).round();
    Map<String, dynamic> side(Map<String, dynamic> order) => {
      'id': order['id'],
      'code': order['code'],
      'tableId': order['tableId'],
      'subtotal': order['subtotal'],
      'discount': order['discountAmount'],
      'promotionDiscount': order['promotionDiscountAmount'],
      'promotionName': order['promotionName'],
      'total': order['total'],
      'paid': paidAmount(order['id'] as int),
    };
    final merged = plan.merged;
    final paid =
        cents(paidAmount(targetOrderId)) + cents(paidAmount(sourceOrderId));
    final total = cents(merged['total']);
    final before =
        cents(target['discountAmount']) +
        cents(target['promotionDiscountAmount']) +
        cents(source['discountAmount']) +
        cents(source['promotionDiscountAmount']);
    final after =
        cents(merged['discountAmount']) +
        cents(merged['promotionDiscountAmount']);
    return {
      'target': side(target),
      'source': side(source),
      'merged': {
        'subtotal': merged['subtotal'],
        'discount': merged['discountAmount'],
        'promotionDiscount': merged['promotionDiscountAmount'],
        'promotionName': merged['promotionName'],
        'serviceCharge': merged['serviceCharge'],
        'vat': merged['vat'],
        'total': merged['total'],
        'paid': paid / 100,
        'remaining': max(total - paid, 0) / 100,
        'refundRequired': max(paid - total, 0) / 100,
      },
      'discountLost': max(before - after, 0) / 100,
    };
  }

  /// รวมบิล — mirror ของ order.service.js#mergeOrders: ย้ายรายการ การชำระ การคืนเงิน และส่วนลดไปที่ปลายทาง
  /// แล้วปิดต้นทางโดยไม่มียอดเงินค้าง (T09 #96) ยอดใหม่ต่ำกว่าเงินที่รับไว้ถูกปฏิเสธตามกติกา T07
  Map<String, dynamic> mergeOrders(
    int targetOrderId,
    int sourceOrderId, {
    int? actorId,
  }) {
    final target = findOrder(targetOrderId);
    final source = findOrder(sourceOrderId);
    final plan = _planMerge(target, source);
    final movedPaid = paidAmount(sourceOrderId);
    final movedDiscount = source['discountAmount'];
    final sourcePromotion = source['promotionName'];

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
    for (final row in [...payments, ...refunds]) {
      if (row['orderId'] == source['id']) row['orderId'] = target['id'];
    }
    target['discountType'] = plan.discountType;
    target['discountValue'] = plan.discountValue;
    target['promotionId'] = plan.owner['promotionId'];
    target['promotionName'] = plan.owner['promotionName'];
    target['promotionCode'] = plan.owner['promotionCode'];

    // ต้นทางไม่เหลือรายการ เงิน หรือส่วนลด ยอดเป็น 0 ไม่ถูกนับในรายงาน
    source['discountType'] = DiscountType.none;
    source['discountValue'] = 0.0;
    source['promotionId'] = null;
    source['promotionName'] = null;
    source['promotionCode'] = null;
    _recalculate(source, settle: false);
    source['status'] = OrderStatus.cancelled;
    source['cancelledReason'] = 'order_merged_into_reason'.trParams({
      'code': target['code'] as String,
    });
    source['closedAt'] = _now();
    _freeTable(source);

    // mirror ของ order.service.js#mergeOrders — ดู docs/tickets/13-order-audit-trail.md
    _logAudit(
      actorId: actorId,
      action: 'order.merge',
      summaryArgs: {'source': source['code'], 'target': target['code']},
      entityType: 'order',
      entityId: target['id'] as int,
      summary: 'รวมบิล #${source['code']} เข้ากับ #${target['code']}',
      metadata: {
        'targetOrderCode': target['code'],
        'sourceOrderCode': source['code'],
        'movedPaid': movedPaid,
        'movedDiscount': movedDiscount,
        'sourcePromotion': sourcePromotion,
        'mergedPromotion': plan.merged['promotionName'],
      },
    );

    return _recalculate(target);
  }

  Map<String, dynamic> cancelOrder(int orderId, String reason, {int? actorId}) {
    final order = findOrder(orderId);
    if (order['status'] == OrderStatus.paid) {
      throw ApiException(
        message: 'order_error_already_paid_cannot_cancel'.tr,
        statusCode: 409,
      );
    }
    // ยกเลิกออเดอร์ที่ยังถือเงินลูกค้าไว้ไม่ได้ ต้องคืนให้ครบก่อน — mirror ของ order.service.js#assertNoMoneyHeld
    // (T08 #100, docs/DECISIONS.md #77 D2)
    final held = (paidAmount(orderId) * 100).round();
    if (held > 0) {
      throw ApiException(
        message: 'order_error_refund_before_cancel'.trParams({
          'paid': (held / 100).toStringAsFixed(2),
        }),
        statusCode: 409,
        code: 'REFUND_REQUIRED',
      );
    }

    // ยกเลิกทั้งบิล คืนสต๊อกให้ทุกรายการที่เคยตัดไปแล้วและยังไม่ถูกยกเลิก
    // (รวมรายการที่เสิร์ฟไปแล้วด้วย — mirror ของ order.service.js#cancel)
    for (final item in (order['items'] as List).cast<Map<String, dynamic>>()) {
      if (item['status'] != OrderItemStatus.cancelled &&
          item['stockDeducted'] == true) {
        restoreForOrderItem(item);
      }
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

    _logAudit(
      actorId: actorId,
      action: 'order.cancel',
      summaryArgs: {'code': order['code']},
      entityType: 'order',
      entityId: order['id'] as int,
      summary: 'ยกเลิกออเดอร์ #${order['code']}',
      reason: reason,
      metadata: {'orderCode': order['code']},
    );

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

  void _assertMutable(Map<String, dynamic> order) {
    if (!OrderStatus.isActive(order['status'] as String)) {
      throw ApiException(
        message: 'order_error_closed_cannot_edit'.tr,
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

  /// แก้ออเดอร์แบบทั้งหมดหรือไม่มีเลย — mirror ของ transaction ใน order.service.js#changeOrder (T02 #81)
  /// การแก้ในโหมดสาธิตเปลี่ยนข้อมูลในหน่วยความจำทีละขั้น (สต๊อก, audit, โต๊ะ) ถ้ากติกาหลังคำนวณยอดปฏิเสธ (T07) จึงคืนทุกอย่าง
  /// กลับเป็นก่อนกด บิลไม่ค้างครึ่งทาง
  T atomically<T>(T Function() change) {
    List<Map<String, dynamic>> copyRows(List<Map<String, dynamic>> rows) =>
        rows.map((row) => _deepCopy(row) as Map<String, dynamic>).toList();
    final savedOrders = copyRows(orders);
    final savedIngredients = copyRows(ingredients);
    final savedTables = copyRows(tables);
    final savedCustomers = copyRows(customers);
    final auditCount = auditLogs.length;
    try {
      return change();
    } catch (_) {
      orders
        ..clear()
        ..addAll(savedOrders);
      ingredients = savedIngredients;
      tables = savedTables;
      customers
        ..clear()
        ..addAll(savedCustomers);
      auditLogs.removeRange(auditCount, auditLogs.length);
      rethrow;
    }
  }

  static dynamic _deepCopy(dynamic value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries)
          '${entry.key}': _deepCopy(entry.value),
      };
    }
    if (value is List) return value.map(_deepCopy).toList();
    return value;
  }

  /// ยอดบิลที่ยังเปิดต้องไม่ต่ำกว่าเงินที่ร้านถือไว้สุทธิ — mirror ของ order.service.js#settleIfCovered (T07 #105,
  /// docs/DECISIONS.md #95) ยอดใหม่ต่ำกว่า = ปฏิเสธพร้อมยอดที่ต้องคืน, เท่ากันพอดี = ปิดบิลเหมือนรอบจ่ายสุดท้าย
  void _settleIfCovered(Map<String, dynamic> order) {
    const open = [OrderStatus.open, OrderStatus.inKitchen, OrderStatus.served];
    if (!open.contains(order['status'])) return;
    final paidSatang = (paidAmount(order['id'] as int) * 100).round();
    final totalSatang = ((order['total'] as num).toDouble() * 100).round();
    if (paidSatang > 0 && totalSatang == paidSatang) {
      _closeFullyPaidOrder(order);
      return;
    }
    if (totalSatang >= paidSatang) return;
    throw ApiException(
      message: 'order_error_total_below_paid'.trParams({
        'total': (totalSatang / 100).toStringAsFixed(2),
        'paid': (paidSatang / 100).toStringAsFixed(2),
        'refund': ((paidSatang - totalSatang) / 100).toStringAsFixed(2),
      }),
      statusCode: 409,
    );
  }

  /// คิดยอดใหม่ทั้งบิลด้วยกฎเดียวกับ backend แล้วตรวจกติกายอดบิลกับเงินที่รับไว้ (T07) — ข้อมูลตัวอย่างย้อนหลังส่ง
  /// `settle: false` เพราะสร้างบิลก่อนแล้วค่อยใส่การชำระ
  Map<String, dynamic> _recalculate(
    Map<String, dynamic> order, {
    bool settle = true,
  }) {
    final items = (order['items'] as List).cast<Map<String, dynamic>>();
    final subtotal = items
        .where((item) => item['status'] != OrderItemStatus.cancelled)
        .fold<double>(
          0,
          (sum, item) => sum + (item['lineTotal'] as num).toDouble(),
        );

    final type = order['discountType'] as String;
    final value = (order['discountValue'] as num).toDouble();
    final promo = _resolvePromotionForOrder(order, items);

    final bill = _calculator.fromSubtotal(
      subtotal,
      discountAmount: type == DiscountType.amount ? value : 0,
      discountPercent: type == DiscountType.percent ? value : 0,
      promotionDiscountAmount: promo['discountAmount'] as double,
    );

    order['subtotal'] = bill.subtotal;
    order['discountAmount'] = bill.discount;
    order['promotionId'] = promo['promotionId'];
    order['promotionName'] = promo['name'];
    order['promotionCode'] = promo['code'];
    order['promotionDiscountAmount'] = bill.promotionDiscount;
    order['serviceCharge'] = bill.serviceCharge;
    order['vat'] = bill.vat;
    order['total'] = bill.total;
    order['updatedAt'] = _now();

    if (settle) _settleIfCovered(order);
    return order;
  }
}
