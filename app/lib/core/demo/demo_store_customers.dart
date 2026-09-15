part of 'demo_store.dart';

// -------------------------------------------------------- customers -----
/// ลูกค้า/สมาชิก + แต้มสะสม (ดู docs/tickets/09-customer-loyalty.md) — mirror ของ
/// backend customer.service.js
extension DemoStoreCustomers on DemoStore {
  Map<String, dynamic> findCustomer(int id) => customers.firstWhere(
    (row) => row['id'] == id,
    orElse: () => throw ApiException(
      message: 'customer_error_not_found'.tr,
      statusCode: 404,
    ),
  );

  List<Map<String, dynamic>> customerSearch({String? search}) {
    final query = search?.trim().toLowerCase();
    final result =
        customers.where((row) {
          if (query == null || query.isEmpty) return true;
          final name = (row['name'] as String).toLowerCase();
          final phone = row['phone'] as String;
          return name.contains(query) || phone.contains(query);
        }).toList()..sort(
          (a, b) => (a['name'] as String).compareTo(b['name'] as String),
        );
    return result;
  }

  Map<String, dynamic> createCustomer({
    required String name,
    required String phone,
    String? email,
  }) {
    if (customers.any((row) => row['phone'] == phone)) {
      throw ApiException(
        message: 'customer_error_phone_taken'.tr,
        statusCode: 409,
      );
    }
    final customer = {
      'id': _nextId(),
      'name': name,
      'phone': phone,
      'email': email,
      'pointsBalance': 0,
      'createdAt': _now(),
      'updatedAt': _now(),
    };
    customers.add(customer);
    return customer;
  }

  /// บวก/ลบแต้มสะสม (delta ติดลบ = ใช้แต้ม, บวก = สะสมแต้ม)
  Map<String, dynamic> adjustCustomerPoints(int id, int delta) {
    final customer = findCustomer(id);
    customer['pointsBalance'] = (customer['pointsBalance'] as int) + delta;
    customer['updatedAt'] = _now();
    return customer;
  }
}
