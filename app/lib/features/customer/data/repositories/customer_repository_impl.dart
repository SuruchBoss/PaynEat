import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_data_source.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  const CustomerRepositoryImpl(this._remote);

  final CustomerRemoteDataSource _remote;

  @override
  Future<Result<({List<Customer> customers, int total})>> search({
    String? search,
    int page = 1,
    int limit = 20,
  }) => guard(() async {
    final result = await _remote.search(
      search: search,
      page: page,
      limit: limit,
    );
    return (customers: result.customers.cast<Customer>(), total: result.total);
  });

  @override
  Future<Result<Customer>> getById(int id) => guard(() => _remote.getById(id));

  @override
  Future<Result<Customer>> create({
    required String name,
    required String phone,
    String? email,
  }) => guard(() => _remote.create(name: name, phone: phone, email: email));

  @override
  Future<Result<Customer>> updateCredit(int id, CustomerCreditTerms terms) =>
      guard(() => _remote.updateCredit(id, terms));
}
