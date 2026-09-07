part of 'demo_store.dart';

// ----------------------------------------------------------- tables -----
extension DemoStoreTables on DemoStore {
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
}
