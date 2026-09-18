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
      'promotionDiscount': sum('promotionDiscountAmount'),
      'totalDiscount': sum('discountAmount') + sum('promotionDiscountAmount'),
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

  /// Z-report ต่อวัน (รวมทุกกะ) — mirror ของ backend reportService.zReportByDate
  /// (ดู docs/tickets/12-report-export.md)
  Map<String, dynamic> zReportByDate(String? date) {
    final day = date ?? _today();
    return {'type': 'date', 'date': day, ...salesSummary(from: day, to: day)};
  }

  /// Z-report ต่อกะเดียว พร้อมกระทบยอดเงินสด — คิดจากออเดอร์ที่จ่ายจริงในกะนี้เท่านั้น
  /// (ผ่าน payments.shiftId ไม่ใช่วันที่เปิดออเดอร์ เหมือนฝั่ง backend)
  Map<String, dynamic> zReportByShift(int shiftId) {
    final shift = shifts.firstWhere(
      (row) => row['id'] == shiftId,
      orElse: () => throw ApiException(
        message: 'shift_error_not_found'.tr,
        statusCode: 404,
      ),
    );

    final shiftPayments = payments
        .where((row) => row['shiftId'] == shiftId)
        .toList(growable: false);
    final paidOrderIds = shiftPayments.map((row) => row['orderId']).toSet();
    final shiftOrders = orders
        .where((row) => paidOrderIds.contains(row['id']))
        .toList(growable: false);

    double sum(String key) => shiftOrders.fold<double>(
      0,
      (total, order) => total + (order[key] as num).toDouble(),
    );
    final refundTotal = refunds
        .where((row) => paidOrderIds.contains(row['orderId']))
        .fold<double>(0, (total, row) => total + (row['amount'] as num));
    final guests = shiftOrders.fold<int>(
      0,
      (total, order) => total + (order['guestCount'] as int),
    );

    final byMethod = <String, Map<String, dynamic>>{};
    for (final payment in shiftPayments) {
      final method = payment['method'] as String;
      final entry = byMethod.putIfAbsent(
        method,
        () => {'method': method, 'count': 0, 'amount': 0.0},
      );
      entry['count'] = (entry['count'] as int) + 1;
      entry['amount'] =
          (entry['amount'] as double) + (payment['amount'] as num).toDouble();
    }

    final discount = sum('discountAmount');
    final promotionDiscount = sum('promotionDiscountAmount');

    return {
      'type': 'shift',
      'shift': shift,
      'orderCount': shiftOrders.length,
      'guestCount': guests,
      'subtotal': sum('subtotal'),
      'discount': discount,
      'promotionDiscount': promotionDiscount,
      'totalDiscount': discount + promotionDiscount,
      'serviceCharge': sum('serviceCharge'),
      'vat': sum('vat'),
      'refundTotal': refundTotal,
      'netSales': sum('total') - refundTotal,
      'paymentMethods': byMethod.values.toList(growable: false),
    };
  }

  /// export รายงานเป็น CSV — mirror ของ backend reportService.export*Csv ตัวต่อตัว
  /// (ดู docs/tickets/12-report-export.md)
  String exportSummaryCsv({String? from, String? to}) {
    final summary = salesSummary(from: from, to: to);
    final range = summary['range'] as Map<String, dynamic>;
    final paymentMethods =
        summary['paymentMethods'] as List<Map<String, dynamic>>;

    final rows = <({String label, Object? value})>[
      (label: 'ช่วงวันที่', value: '${range['from']} ถึง ${range['to']}'),
      (label: 'จำนวนออเดอร์', value: summary['orderCount']),
      (label: 'จำนวนลูกค้า', value: summary['guestCount']),
      (label: 'ยอดขายก่อนหักส่วนลด (บาท)', value: summary['subtotal']),
      (label: 'ส่วนลดที่กรอกเอง (บาท)', value: summary['discount']),
      (label: 'ส่วนลดจากโปรโมชัน (บาท)', value: summary['promotionDiscount']),
      (label: 'ส่วนลดรวม (บาท)', value: summary['totalDiscount']),
      (
        label: 'ค่าบริการ Service Charge (บาท)',
        value: summary['serviceCharge'],
      ),
      (label: 'ภาษีมูลค่าเพิ่ม VAT (บาท)', value: summary['vat']),
      (label: 'ยอดคืนเงิน (บาท)', value: summary['refundTotal']),
      (label: 'ยอดขายสุทธิ (บาท)', value: summary['netSales']),
      for (final p in paymentMethods)
        (
          label: 'ช่องทาง: ${p['method']} (${p['count']} รายการ, บาท)',
          value: p['amount'],
        ),
    ];
    return toCsv(rows, [
      (label: 'รายการ', value: (({String label, Object? value}) r) => r.label),
      (label: 'มูลค่า', value: (({String label, Object? value}) r) => r.value),
    ]);
  }

  String exportTopItemsCsv({String? from, String? to, int limit = 10}) {
    return toCsv(topItems(from: from, to: to, limit: limit), [
      (label: 'เมนู', value: (Map<String, dynamic> r) => r['name']),
      (
        label: 'จำนวนที่ขายได้',
        value: (Map<String, dynamic> r) => r['quantity'],
      ),
      (label: 'รายได้ (บาท)', value: (Map<String, dynamic> r) => r['revenue']),
    ]);
  }

  String exportSalesByDayCsv({String? from, String? to}) {
    return toCsv(salesByDay(from: from, to: to), [
      (label: 'วันที่', value: (Map<String, dynamic> r) => r['day']),
      (
        label: 'จำนวนออเดอร์',
        value: (Map<String, dynamic> r) => r['orderCount'],
      ),
      (label: 'ยอดขายรวม (บาท)', value: (Map<String, dynamic> r) => r['total']),
    ]);
  }

  List<({String label, Object? value})> _zReportRows(Map<String, dynamic> z) {
    final isShift = z['type'] == 'shift';
    final shift = isShift ? z['shift'] as Map<String, dynamic> : null;
    final paymentMethods = z['paymentMethods'] as List<Map<String, dynamic>>;

    final rows = <({String label, Object? value})?>[
      (label: 'ประเภท', value: isShift ? 'รายกะ' : 'รายวัน'),
      isShift
          ? (label: 'กะที่', value: shift!['id'])
          : (label: 'วันที่', value: z['date']),
      isShift
          ? (
              label: 'เปิดกะโดย',
              value: '${shift!['openedByName']} (${shift['openedAt']})',
            )
          : null,
      isShift && shift!['closedAt'] != null
          ? (
              label: 'ปิดกะโดย',
              value: '${shift['closedByName']} (${shift['closedAt']})',
            )
          : null,
      (label: 'จำนวนออเดอร์', value: z['orderCount']),
      (label: 'จำนวนลูกค้า', value: z['guestCount']),
      (label: 'ยอดขายก่อนหักส่วนลด (บาท)', value: z['subtotal']),
      (label: 'ส่วนลดที่กรอกเอง (บาท)', value: z['discount']),
      (label: 'ส่วนลดจากโปรโมชัน (บาท)', value: z['promotionDiscount']),
      (label: 'ส่วนลดรวม (บาท)', value: z['totalDiscount']),
      (label: 'ค่าบริการ Service Charge (บาท)', value: z['serviceCharge']),
      (label: 'ภาษีมูลค่าเพิ่ม VAT (บาท)', value: z['vat']),
      (label: 'ยอดคืนเงิน (บาท)', value: z['refundTotal']),
      (label: 'ยอดขายสุทธิ (บาท)', value: z['netSales']),
      for (final p in paymentMethods)
        (
          label: 'ช่องทาง: ${p['method']} (${p['count']} รายการ, บาท)',
          value: p['amount'],
        ),
      if (isShift) ...[
        (label: 'เงินสดตั้งต้น (บาท)', value: shift!['openingCash']),
        (label: 'เงินสดที่คาดไว้ (บาท)', value: shift['expectedCash']),
        (label: 'เงินสดที่นับได้จริง (บาท)', value: shift['countedCash']),
        (label: 'ส่วนต่างเงินสด (บาท)', value: shift['variance']),
      ],
    ];
    return rows.nonNulls.toList(growable: false);
  }

  String exportZReportCsv(Map<String, dynamic> z) {
    return toCsv(_zReportRows(z), [
      (label: 'รายการ', value: (({String label, Object? value}) r) => r.label),
      (label: 'มูลค่า', value: (({String label, Object? value}) r) => r.value),
    ]);
  }

  String exportZReportByShiftCsv(int shiftId) =>
      exportZReportCsv(zReportByShift(shiftId));

  String exportZReportByDateCsv(String? date) =>
      exportZReportCsv(zReportByDate(date));
}
