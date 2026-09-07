part of 'demo_store.dart';

// ---------------------------------------------------- seed ยอดขายย้อนหลัง ---
extension DemoStoreSeedHistory on DemoStore {
  /// สร้างยอดขายย้อนหลังไว้ให้รายงานและแดชบอร์ดมีข้อมูลให้ดูตั้งแต่เปิดแอป
  void _seedHistoricalSales() {
    final random = Random(20260907);
    final now = DateTime.now();

    for (var dayOffset = 6; dayOffset >= 0; dayOffset--) {
      final billCount = dayOffset == 0 ? 6 : 8 + random.nextInt(6);

      for (var i = 0; i < billCount; i++) {
        // บิลของวันนี้กระจายตั้งแต่เวลาเปิดร้านจนถึงตอนนี้
        // ถ้ายังไม่ถึงเวลาเปิดร้าน (เช่นเปิดแอปตอนเช้ามืด) ใช้ช่วงไม่กี่ชั่วโมงที่ผ่านมาแทน
        // เพื่อให้กราฟยอดขายรายชั่วโมงมีข้อมูลเสมอ ไม่ว่าจะเปิดแอปตอนไหน
        final DateTime createdAt;
        if (dayOffset == 0) {
          final opened = DateTime(
            now.year,
            now.month,
            now.day,
            DemoStore.openingHour,
          );
          final minutesSinceOpen = now.difference(opened).inMinutes;
          createdAt = minutesSinceOpen > 60
              ? opened.add(Duration(minutes: random.nextInt(minutesSinceOpen)))
              : now.subtract(Duration(minutes: 20 + random.nextInt(300)));
        } else {
          createdAt = DateTime(
            now.year,
            now.month,
            now.day,
            DemoStore.openingHour + random.nextInt(10),
            random.nextInt(60),
          ).subtract(Duration(days: dayOffset));
        }
        if (createdAt.isAfter(now)) continue;

        final items = <Map<String, dynamic>>[];
        final lineCount = 1 + random.nextInt(4);
        for (var line = 0; line < lineCount; line++) {
          final menu = menuItems[random.nextInt(menuItems.length)];
          final quantity = 1 + random.nextInt(2);
          final unitPrice = (menu['price'] as num).toDouble();
          items.add({
            'id': _nextId(),
            'orderId': 0,
            'menuItemId': menu['id'],
            'name': menu['name'],
            'unitPrice': unitPrice,
            'quantity': quantity,
            'options': const [],
            'optionsPrice': 0.0,
            'lineTotal': unitPrice * quantity,
            'note': null,
            'status': OrderItemStatus.served,
            'createdAt': createdAt.toUtc().toIso8601String(),
            'updatedAt': createdAt.toUtc().toIso8601String(),
          });
        }

        final guestCount = 1 + random.nextInt(4);
        final order = <String, dynamic>{
          'id': _nextId(),
          'code':
              'ORD-${createdAt.year}'
              '${createdAt.month.toString().padLeft(2, '0')}'
              '${createdAt.day.toString().padLeft(2, '0')}'
              '-${(i + 1).toString().padLeft(4, '0')}',
          'type': OrderType.dineIn,
          'tableId': null,
          'tableName': tables[random.nextInt(tables.length)]['name'],
          'tableZone': null,
          'waiterId': 3,
          'waiterName': 'น้องฝน (พนักงานเสิร์ฟ)',
          'guestCount': guestCount,
          'status': OrderStatus.paid,
          'note': null,
          'subtotal': 0.0,
          'discountType': DiscountType.none,
          'discountValue': 0.0,
          'discountAmount': 0.0,
          'serviceCharge': 0.0,
          'vat': 0.0,
          'total': 0.0,
          'cancelledReason': null,
          'createdAt': createdAt.toUtc().toIso8601String(),
          'updatedAt': createdAt.toUtc().toIso8601String(),
          'closedAt': createdAt.toUtc().toIso8601String(),
          'items': items,
        };

        for (final item in items) {
          item['orderId'] = order['id'];
        }

        orders.add(order);
        _recalculate(order);

        final method = const [
          PaymentMethod.cash,
          PaymentMethod.qr,
          PaymentMethod.card,
          PaymentMethod.transfer,
        ][random.nextInt(4)];
        payments.add({
          'id': _nextId(),
          'orderId': order['id'],
          'method': method,
          'amount': order['total'],
          'received': order['total'],
          'change': 0.0,
          'reference': null,
          'cashierId': 6,
          'cashierName': 'พี่แอน (แคชเชียร์)',
          'createdAt': createdAt.toUtc().toIso8601String(),
        });
      }
    }

    _orderSequence = orders.where((o) {
      final day = (o['createdAt'] as String).substring(0, 10);
      return day == _today();
    }).length;
  }
}
