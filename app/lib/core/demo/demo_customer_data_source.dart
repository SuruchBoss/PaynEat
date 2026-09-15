part of 'demo_data_sources.dart';

class DemoCustomerDataSource implements CustomerRemoteDataSource {
  const DemoCustomerDataSource(this._store);

  final DemoStore _store;

  @override
  Future<({List<CustomerModel> customers, int total})> search({
    String? search,
    int page = 1,
    int limit = 20,
  }) => _delayed(() {
    final rows = _store.customerSearch(search: search);
    final start = ((page - 1) * limit).clamp(0, rows.length);
    final end = (start + limit).clamp(0, rows.length);
    return (
      customers: rows
          .sublist(start, end)
          .map(CustomerModel.fromJson)
          .toList(growable: false),
      total: rows.length,
    );
  });

  @override
  Future<CustomerModel> getById(int id) =>
      _delayed(() => CustomerModel.fromJson(_store.findCustomer(id)));

  @override
  Future<CustomerModel> create({
    required String name,
    required String phone,
    String? email,
  }) => _delayed(
    () => CustomerModel.fromJson(
      _store.createCustomer(name: name, phone: phone, email: email),
    ),
  );
}
