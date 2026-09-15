part of 'demo_store.dart';

// ---------------------------------------------------------- reports -----
extension DemoStoreReports on DemoStore {
  List<Map<String, dynamic>> _paidOrdersBetween(String? from, String? to) {
    return orders
        .where((order) {
          if (order['status'] != OrderStatus.paid) return false;
          final day = (order['createdAt'] as String).substring(0, 10);
          if (from != null && day.compareTo(from) < 0) return false;
          if (to != null && day.compareTo(to) > 0) return false;
          return true;
        })
        .toList(growable: false);
  }

  Map<String, dynamic> salesSummary({String? from, String? to}) {
    final today = _today();
    final start = from ?? today;
    final end = to ?? start;
    final paidOrders = _paidOrdersBetween(start, end);

    double sum(String key) => paidOrders.fold<double>(
      0,
      (total, order) => total + (order[key] as num).toDouble(),
    );

    final refundTotal = refunds
        .where((refund) {
          final day = (refund['createdAt'] as String).substring(0, 10);
          return day.compareTo(start) >= 0 && day.compareTo(end) <= 0;
        })
        .fold<double>(
          0,
          (total, refund) => total + (refund['amount'] as num).toDouble(),
        );
    final netSales = sum('total') - refundTotal;
    final guests = paidOrders.fold<int>(
      0,
      (total, order) => total + (order['guestCount'] as int),
    );

    final byMethod = <String, Map<String, dynamic>>{};
    for (final payment in payments) {
      final order = orders.firstWhere(
        (row) => row['id'] == payment['orderId'],
        orElse: () => const {},
      );
      if (order.isEmpty || order['status'] != OrderStatus.paid) continue;
      final day = (order['createdAt'] as String).substring(0, 10);
      if (day.compareTo(start) < 0 || day.compareTo(end) > 0) continue;

      final method = payment['method'] as String;
      final entry = byMethod.putIfAbsent(
        method,
        () => {'method': method, 'count': 0, 'amount': 0.0},
      );
      entry['count'] = (entry['count'] as int) + 1;
      entry['amount'] =
          (entry['amount'] as double) + (payment['amount'] as num).toDouble();
    }

    final byCategory = <String, Map<String, dynamic>>{};
    for (final order in paidOrders) {
      for (final item
          in (order['items'] as List).cast<Map<String, dynamic>>()) {
        if (item['status'] == OrderItemStatus.cancelled) continue;
        final menu = menuItems.firstWhere(
          (row) => row['id'] == item['menuItemId'],
          orElse: () => {'categoryName': 'report_uncategorized'.tr},
        );
        final name =
            menu['categoryName'] as String? ?? 'report_uncategorized'.tr;
        final entry = byCategory.putIfAbsent(
          name,
          () => {'category': name, 'quantity': 0, 'revenue': 0.0},
        );
        entry['quantity'] =
            (entry['quantity'] as int) + (item['quantity'] as int);
        entry['revenue'] =
            (entry['revenue'] as double) +
            (item['lineTotal'] as num).toDouble();
      }
    }

    return {
      'range': {'from': start, 'to': end},
      'orderCount': paidOrders.length,
      'guestCount': guests,
      'subtotal': sum('subtotal'),
      'discount': sum('discountAmount'),
      'serviceCharge': sum('serviceCharge'),
      'vat': sum('vat'),
      'refundTotal': refundTotal,
      'netSales': netSales,
      'averagePerOrder': paidOrders.isEmpty
          ? 0.0
          : netSales / paidOrders.length,
      'averagePerGuest': guests == 0 ? 0.0 : netSales / guests,
      'paymentMethods': byMethod.values.toList(growable: false),
      'categories': byCategory.values.toList(growable: false),
    };
  }

  List<Map<String, dynamic>> topItems({
    String? from,
    String? to,
    int limit = 10,
  }) {
    final counters = <String, Map<String, dynamic>>{};

    for (final order in _paidOrdersBetween(
      from ?? _today(),
      to ?? from ?? _today(),
    )) {
      for (final item
          in (order['items'] as List).cast<Map<String, dynamic>>()) {
        if (item['status'] == OrderItemStatus.cancelled) continue;
        final name = item['name'] as String;
        final entry = counters.putIfAbsent(
          name,
          () => {
            'menuItemId': item['menuItemId'],
            'name': name,
            'quantity': 0,
            'revenue': 0.0,
          },
        );
        entry['quantity'] =
            (entry['quantity'] as int) + (item['quantity'] as int);
        entry['revenue'] =
            (entry['revenue'] as double) +
            (item['lineTotal'] as num).toDouble();
      }
    }

    final result = counters.values.toList()
      ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    return result.take(limit).toList(growable: false);
  }

  List<Map<String, dynamic>> salesByDay({String? from, String? to}) {
    final byDay = <String, Map<String, dynamic>>{};

    for (final order in _paidOrdersBetween(from, to)) {
      final day = (order['createdAt'] as String).substring(0, 10);
      final entry = byDay.putIfAbsent(
        day,
        () => {'day': day, 'orderCount': 0, 'total': 0.0},
      );
      entry['orderCount'] = (entry['orderCount'] as int) + 1;
      entry['total'] =
          (entry['total'] as double) + (order['total'] as num).toDouble();
    }

    final result = byDay.values.toList()
      ..sort((a, b) => (a['day'] as String).compareTo(b['day'] as String));
    return result;
  }

  Map<String, dynamic> dashboard() {
    final today = _today();
    final hourly = <int, Map<String, dynamic>>{};

    for (final order in _paidOrdersBetween(today, today)) {
      final hour = DateTime.parse(order['createdAt'] as String).toLocal().hour;
      final entry = hourly.putIfAbsent(
        hour,
        () => {'hour': hour, 'orderCount': 0, 'total': 0.0},
      );
      entry['orderCount'] = (entry['orderCount'] as int) + 1;
      entry['total'] =
          (entry['total'] as double) + (order['total'] as num).toDouble();
    }

    return {
      'today': salesSummary(from: today, to: today),
      'hourly': hourly.values.toList(growable: false),
      'topItems': topItems(from: today, to: today, limit: 5),
      'live': {
        'openOrders': orders
            .where((row) => OrderStatus.isActive(row['status'] as String))
            .length,
        'occupiedTables': tables
            .where((row) => row['status'] == TableStatus.occupied)
            .length,
        'totalTables': tables.length,
        'pendingKitchenItems': kitchenQueue(const [
          OrderItemStatus.pending,
          OrderItemStatus.cooking,
        ]).length,
      },
    };
  }

  String _today() => AppClock.now().toIso8601String().substring(0, 10);
}
