import 'dart:math';

import '../../features/order/domain/services/bill_calculator.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import 'demo_seed.dart';

/// "เซิร์ฟเวอร์จำลอง" ที่อยู่ในหน่วยความจำของแอป
///
/// ใช้เฉพาะ Demo Mode เพื่อให้เปิดลิงก์เดียวแล้วลองใช้งานได้ครบทุกฟีเจอร์
/// โดยไม่ต้องรัน backend — เก็บข้อมูลเป็น Map รูปร่างเดียวกับ JSON ของ API จริง
/// จึงใช้ Model.fromJson ตัวเดียวกันได้ทั้งหมด
///
/// ข้อมูลอยู่แค่ในหน่วยความจำ รีเฟรชหน้าเว็บแล้วเริ่มใหม่
class DemoStore {
  DemoStore() {
    reset();
  }

  static final DemoStore instance = DemoStore();

  late List<Map<String, dynamic>> users;
  late List<Map<String, dynamic>> categories;
  late List<Map<String, dynamic>> menuItems;
  late List<Map<String, dynamic>> tables;
  late Map<String, dynamic> settings;

  final List<Map<String, dynamic>> orders = [];
  final List<Map<String, dynamic>> payments = [];

  int _orderSequence = 0;
  int _idSequence = 1000;

  /// หน่วงเวลาเล็กน้อยให้เหมือนเรียก API จริง (จอ loading จึงทำงานสมจริง)
  static const Duration latency = Duration(milliseconds: 180);

  /// เวลาเปิดร้านของข้อมูลตัวอย่าง ใช้กระจายยอดขายให้ดูสมจริง
  static const int openingHour = 11;

  void reset() {
    users = DemoSeed.users();
    categories = DemoSeed.categories();
    menuItems = DemoSeed.menuItems();
    tables = DemoSeed.tables();
    settings = DemoSeed.settings();
    orders.clear();
    payments.clear();
    _orderSequence = 0;
    _idSequence = 1000;
    _seedHistoricalSales();
  }

  int _nextId() => ++_idSequence;

  String _now() => DateTime.now().toUtc().toIso8601String();

  BillCalculator get _calculator => BillCalculator(
    vatRate: settings['vatRate'] as double,
    serviceChargeRate: settings['serviceChargeRate'] as double,
    vatIncluded: settings['vatIncluded'] as bool,
  );

  // ---------------------------------------------------------------- auth ---

  Map<String, dynamic> login(String username, String password) {
    final user = users.firstWhere(
      (row) => row['username'] == username && row['password'] == password,
      orElse: () => throw const ApiException(
        message: 'username หรือรหัสผ่านไม่ถูกต้อง',
        statusCode: 401,
      ),
    );
    return {'token': 'demo-token-${user['id']}', 'user': _publicUser(user)};
  }

  Map<String, dynamic> _publicUser(Map<String, dynamic> user) => {
    'id': user['id'],
    'name': user['name'],
    'username': user['username'],
    'role': user['role'],
    'isActive': user['isActive'],
  };

  Map<String, dynamic> profile(String? token) {
    final id = int.tryParse(token?.split('-').last ?? '');
    final user = users.firstWhere(
      (row) => row['id'] == id,
      orElse: () =>
          throw const ApiException(message: 'เซสชันหมดอายุ', statusCode: 401),
    );
    return _publicUser(user);
  }

  List<Map<String, dynamic>> staff() =>
      users.map(_publicUser).toList(growable: false);

  Map<String, dynamic> createStaff({
    required String name,
    required String username,
    required String password,
    required String role,
  }) {
    if (users.any((row) => row['username'] == username)) {
      throw const ApiException(
        message: 'username นี้ถูกใช้งานแล้ว',
        statusCode: 409,
      );
    }
    final user = {
      'id': _nextId(),
      'name': name,
      'username': username,
      'password': password,
      'role': role,
      'isActive': true,
    };
    users.add(user);
    return _publicUser(user);
  }

  Map<String, dynamic> updateStaff(int id, Map<String, dynamic> changes) {
    final user = _findUser(id);
    changes.forEach((key, value) => user[key] = value);
    return _publicUser(user);
  }

  void deleteStaff(int id) => users.removeWhere((row) => row['id'] == id);

  Map<String, dynamic> _findUser(int id) => users.firstWhere(
    (row) => row['id'] == id,
    orElse: () =>
        throw const ApiException(message: 'ไม่พบผู้ใช้งาน', statusCode: 404),
  );

  // ------------------------------------------------------------ menu ------

  List<Map<String, dynamic>> categoryList() => categories
      .map(
        (category) => {
          ...category,
          'itemCount': menuItems
              .where((item) => item['categoryId'] == category['id'])
              .length,
        },
      )
      .toList(growable: false);

  Map<String, dynamic> saveCategory(Map<String, dynamic> body, {int? id}) {
    if (id == null) {
      final category = {
        'id': _nextId(),
        'name': body['name'],
        'nameEn': body['nameEn'],
        'icon': body['icon'],
        'sortOrder': categories.length + 1,
        'isActive': true,
      };
      categories.add(category);
      return category;
    }
    final category = categories.firstWhere((row) => row['id'] == id);
    body.forEach((key, value) => category[key] = value);
    return category;
  }

  void deleteCategory(int id) {
    if (menuItems.any((item) => item['categoryId'] == id)) {
      throw const ApiException(
        message: 'ลบไม่ได้ เพราะยังมีเมนูอยู่ในหมวดหมู่นี้',
        statusCode: 409,
      );
    }
    categories.removeWhere((row) => row['id'] == id);
  }

  List<Map<String, dynamic>> menuList({
    int? categoryId,
    String? search,
    bool? availableOnly,
  }) {
    return menuItems
        .where((item) {
          if (categoryId != null && item['categoryId'] != categoryId) {
            return false;
          }
          if (availableOnly == true && item['isAvailable'] != true) {
            return false;
          }
          if (search != null && search.isNotEmpty) {
            final name = (item['name'] as String).toLowerCase();
            if (!name.contains(search.toLowerCase())) return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Map<String, dynamic> menuItem(int id) => menuItems.firstWhere(
    (row) => row['id'] == id,
    orElse: () =>
        throw const ApiException(message: 'ไม่พบเมนูนี้', statusCode: 404),
  );

  Map<String, dynamic> saveMenuItem(Map<String, dynamic> body, {int? id}) {
    final categoryName = categories.firstWhere(
      (row) => row['id'] == body['categoryId'],
      orElse: () => categories.first,
    )['name'];

    if (id == null) {
      final item = {
        'id': _nextId(),
        'categoryId': body['categoryId'],
        'categoryName': categoryName,
        'name': body['name'],
        'nameEn': body['nameEn'],
        'description': body['description'],
        'price': body['price'],
        'imageUrl': null,
        'isAvailable': body['isAvailable'] ?? true,
        'isRecommended': body['isRecommended'] ?? false,
        'prepMinutes': body['prepMinutes'] ?? 10,
        'sortOrder': menuItems.length + 1,
        'optionGroups': _normalizeOptionGroups(body['optionGroups']),
      };
      menuItems.add(item);
      return item;
    }

    final item = menuItem(id);
    body.forEach((key, value) {
      if (key == 'optionGroups') {
        item[key] = _normalizeOptionGroups(value);
      } else {
        item[key] = value;
      }
    });
    item['categoryName'] = categoryName;
    return item;
  }

  /// ตัวเลือกที่ส่งมาจากฟอร์มยังไม่มี id จริง — ออก id ให้เหมือนที่ backend ทำ
  List<Map<String, dynamic>> _normalizeOptionGroups(dynamic groups) {
    if (groups is! List) return const [];
    return groups
        .whereType<Map<String, dynamic>>()
        .map((group) {
          return {
            'id': _nextId(),
            'name': group['name'],
            'minSelect': group['minSelect'] ?? 0,
            'maxSelect': group['maxSelect'] ?? 1,
            'isRequired': group['isRequired'] ?? false,
            'options': (group['options'] as List? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(
                  (option) => {
                    'id': _nextId(),
                    'name': option['name'],
                    'priceDelta': option['priceDelta'] ?? 0,
                    'isDefault': option['isDefault'] ?? false,
                  },
                )
                .toList(growable: false),
          };
        })
        .toList(growable: false);
  }

  Map<String, dynamic> setAvailability(int id, bool isAvailable) {
    final item = menuItem(id);
    item['isAvailable'] = isAvailable;
    return item;
  }

  void deleteMenuItem(int id) =>
      menuItems.removeWhere((row) => row['id'] == id);

  // ----------------------------------------------------------- tables -----

  List<Map<String, dynamic>> tableList({String? zone, String? status}) {
    return tables
        .where((table) {
          if (zone != null && table['zone'] != zone) return false;
          if (status != null && table['status'] != status) return false;
          return true;
        })
        .map((table) {
          final order = orders.firstWhere(
            (row) =>
                row['tableId'] == table['id'] &&
                OrderStatus.isActive(row['status'] as String),
            orElse: () => const {},
          );
          return {
            ...table,
            'currentOrder': order.isEmpty
                ? null
                : {
                    'id': order['id'],
                    'code': order['code'],
                    'status': order['status'],
                    'total': order['total'],
                    'guestCount': order['guestCount'],
                    'createdAt': order['createdAt'],
                  },
          };
        })
        .toList(growable: false);
  }

  List<String> zones() =>
      (tables.map((table) => table['zone'] as String).toSet().toList()..sort());

  Map<String, dynamic> _findTable(int id) => tables.firstWhere(
    (row) => row['id'] == id,
    orElse: () =>
        throw const ApiException(message: 'ไม่พบโต๊ะนี้', statusCode: 404),
  );

  Map<String, dynamic> setTableStatus(int id, String status) {
    final table = _findTable(id);
    final hasOpenOrder = orders.any(
      (row) =>
          row['tableId'] == id && OrderStatus.isActive(row['status'] as String),
    );
    if (status == TableStatus.available && hasOpenOrder) {
      throw const ApiException(
        message: 'โต๊ะนี้ยังมีออเดอร์ที่ยังไม่ปิด',
        statusCode: 409,
      );
    }
    table['status'] = status;
    return table;
  }

  Map<String, dynamic> saveTable(Map<String, dynamic> body, {int? id}) {
    if (id == null) {
      final table = {
        'id': _nextId(),
        'name': body['name'],
        'zone': body['zone'] ?? 'main',
        'seats': body['seats'] ?? 4,
        'status': TableStatus.available,
        'isActive': true,
        'currentOrder': null,
      };
      tables.add(table);
      return table;
    }
    final table = _findTable(id);
    body.forEach((key, value) => table[key] = value);
    return table;
  }

  void deleteTable(int id) => tables.removeWhere((row) => row['id'] == id);

  // ----------------------------------------------------------- orders -----

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

  // --------------------------------------------------------- payments -----

  double paidAmount(int orderId) => payments
      .where((row) => row['orderId'] == orderId)
      .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());

  Map<String, dynamic> paymentSummary(int orderId) {
    final order = findOrder(orderId);
    final paid = paidAmount(orderId);
    final total = (order['total'] as num).toDouble();
    return {
      'orderId': orderId,
      'total': total,
      'paid': paid,
      'remaining': max(0, total - paid),
      'payments': payments
          .where((row) => row['orderId'] == orderId)
          .toList(growable: false),
    };
  }

  Map<String, dynamic> pay({
    required int orderId,
    required String method,
    required double amount,
    double? received,
    String? reference,
    int? cashierId,
  }) {
    final order = findOrder(orderId);
    if (order['status'] == OrderStatus.paid) {
      throw const ApiException(
        message: 'ออเดอร์นี้ชำระเงินครบแล้ว',
        statusCode: 409,
      );
    }

    final total = (order['total'] as num).toDouble();
    final alreadyPaid = paidAmount(orderId);
    final remaining = total - alreadyPaid;

    if (amount > remaining + 0.001) {
      throw ApiException(
        message:
            'ยอดชำระเกินยอดคงเหลือ (คงเหลือ ${remaining.toStringAsFixed(2)} บาท)',
        statusCode: 400,
      );
    }

    final actualReceived = method == PaymentMethod.cash
        ? (received ?? amount)
        : amount;
    final payment = {
      'id': _nextId(),
      'orderId': orderId,
      'method': method,
      'amount': amount,
      'received': actualReceived,
      'change': method == PaymentMethod.cash
          ? max(0, actualReceived - amount)
          : 0.0,
      'reference': reference,
      'cashierId': cashierId,
      'cashierName': cashierId == null ? null : _findUser(cashierId)['name'],
      'createdAt': _now(),
    };
    payments.add(payment);

    final isFullyPaid = alreadyPaid + amount >= total - 0.001;
    if (isFullyPaid) {
      order['status'] = OrderStatus.paid;
      order['closedAt'] = _now();
      _freeTable(order);
    }

    return {
      'payment': payment,
      'order': order,
      'isFullyPaid': isFullyPaid,
      'remaining': max(0, total - (alreadyPaid + amount)),
    };
  }

  Map<String, dynamic> receipt(int orderId) {
    final order = findOrder(orderId);
    return {
      'store': {
        'name': settings['storeName'],
        'currency': settings['currency'],
        'vatRate': settings['vatRate'],
        'serviceChargeRate': settings['serviceChargeRate'],
      },
      'order': order,
      'payments': payments
          .where((row) => row['orderId'] == orderId)
          .toList(growable: false),
      'paidAt': order['closedAt'],
      'changeTotal': payments
          .where((row) => row['orderId'] == orderId)
          .fold<double>(
            0,
            (sum, row) => sum + (row['change'] as num).toDouble(),
          ),
    };
  }

  // ---------------------------------------------------------- reports -----

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

    final netSales = sum('total');
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
          orElse: () => const {'categoryName': 'ไม่ระบุหมวดหมู่'},
        );
        final name = menu['categoryName'] as String? ?? 'ไม่ระบุหมวดหมู่';
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

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

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
          final opened = DateTime(now.year, now.month, now.day, openingHour);
          final minutesSinceOpen = now.difference(opened).inMinutes;
          createdAt = minutesSinceOpen > 60
              ? opened.add(Duration(minutes: random.nextInt(minutesSinceOpen)))
              : now.subtract(Duration(minutes: 20 + random.nextInt(300)));
        } else {
          createdAt = DateTime(
            now.year,
            now.month,
            now.day,
            openingHour + random.nextInt(10),
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
