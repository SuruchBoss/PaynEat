import '../../../../core/usecases/result.dart';
import '../entities/customer.dart';

abstract class CustomerRepository {
  Future<Result<({List<Customer> customers, int total})>> search({
    String? search,
    int page,
    int limit,
  });

  Future<Result<Customer>> getById(int id);

  Future<Result<Customer>> create({
    required String name,
    required String phone,
    String? email,
  });
}
