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
    orElse: () => throw ApiException(
      message: 'table_error_not_found'.tr,
      statusCode: 404,
    ),
  );

  Map<String, dynamic> setTableStatus(int id, String status) {
    final table = _findTable(id);
    final hasOpenOrder = orders.any(
      (row) =>
          row['tableId'] == id && OrderStatus.isActive(row['status'] as String),
    );
    if (status == TableStatus.available && hasOpenOrder) {
      throw ApiException(
        message: 'table_error_has_open_order'.tr,
        statusCode: 409,
      );
    }
    table['status'] = status;
    return table;
  }

  Map<String, dynamic> saveTable(Map<String, dynamic> body, {int? id}) {
    if (id == null) {
      final newId = _nextId();
      final table = {
        'id': newId,
        'name': body['name'],
        'zone': body['zone'] ?? 'main',
        'seats': body['seats'] ?? 4,
        'status': TableStatus.available,
        'isActive': true,
        'currentOrder': null,
        'qrToken': 'demo-table-$newId',
      };
      tables.add(table);
      return table;
    }
    final table = _findTable(id);
    body.forEach((key, value) => table[key] = value);
    return table;
  }

  void deleteTable(int id) => tables.removeWhere((row) => row['id'] == id);

  /// หาโต๊ะจาก qrToken สำหรับหน้าสั่งอาหารเอง (ดู docs/tickets/17-qr-self-order.md) — โยน 404 ถ้า
  /// ไม่พบหรือโต๊ะปิดใช้งานอยู่ (โหมดสาธิตมีสาขาเดียวเสมอ ไม่ต้องเช็คสถานะสาขาซ้ำเหมือน backend จริง)
  Map<String, dynamic> resolveTableByQrToken(String qrToken) {
    final table = tables.firstWhere(
      (row) => row['qrToken'] == qrToken,
      orElse: () => const {},
    );
    if (table.isEmpty || table['isActive'] != true) {
      throw ApiException(
        message: 'self_order_table_unavailable'.tr,
        statusCode: 404,
      );
    }
    return table;
  }

  /// token ใหม่แทนอันเดิม — ใช้ตอนกด "เปลี่ยน QR" ที่หน้าจัดการโต๊ะ (ดู
  /// docs/tickets/17-qr-self-order.md)
  Map<String, dynamic> regenerateQrToken(int id) {
    final table = _findTable(id);
    table['qrToken'] = 'demo-table-$id-${_nextId()}';
    return table;
  }
}
