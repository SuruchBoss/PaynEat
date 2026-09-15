import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<({List<CustomerModel> customers, int total})> search({
    String? search,
    int page,
    int limit,
  });

  Future<CustomerModel> getById(int id);

  Future<CustomerModel> create({
    required String name,
    required String phone,
    String? email,
  });
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  const CustomerRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<({List<CustomerModel> customers, int total})> search({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _client.get(
      ApiEndpoints.customers,
      query: {'search': ?search, 'page': page, 'limit': limit},
    );
    return (
      customers: result.asList
          .map(CustomerModel.fromJson)
          .toList(growable: false),
      total: result.total,
    );
  }

  @override
  Future<CustomerModel> getById(int id) async {
    final result = await _client.get(ApiEndpoints.customer(id));
    return CustomerModel.fromJson(result.asMap);
  }

  @override
  Future<CustomerModel> create({
    required String name,
    required String phone,
    String? email,
  }) async {
    final result = await _client.post(
      ApiEndpoints.customers,
      body: {
        'name': name,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
    return CustomerModel.fromJson(result.asMap);
  }
}
