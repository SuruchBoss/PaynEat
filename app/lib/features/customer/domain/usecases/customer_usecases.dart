import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class SearchCustomersParams {
  const SearchCustomersParams({this.search, this.page = 1, this.limit = 20});

  final String? search;
  final int page;
  final int limit;
}

/// ค้นหาลูกค้าจากชื่อหรือเบอร์โทร — ใช้ตอนเปิดออเดอร์/เช็คบิล และหน้าประวัติของ admin
class SearchCustomersUseCase
    implements
        UseCase<
          ({List<Customer> customers, int total}),
          SearchCustomersParams
        > {
  const SearchCustomersUseCase(this._repository);

  final CustomerRepository _repository;

  @override
  Future<Result<({List<Customer> customers, int total})>> call(
    SearchCustomersParams params,
  ) => _repository.search(
    search: params.search,
    page: params.page,
    limit: params.limit,
  );
}

class GetCustomerUseCase implements UseCase<Customer, int> {
  const GetCustomerUseCase(this._repository);

  final CustomerRepository _repository;

  @override
  Future<Result<Customer>> call(int params) => _repository.getById(params);
}

class CreateCustomerParams {
  const CreateCustomerParams({
    required this.name,
    required this.phone,
    this.email,
  });

  final String name;
  final String phone;
  final String? email;
}

class UpdateCustomerCreditParams {
  const UpdateCustomerCreditParams({required this.id, required this.terms});

  final int id;
  final CustomerCreditTerms terms;
}

/// ตั้งวงเงินเครดิตให้ลูกค้า — ขายเชื่อได้เมื่อวงเงินมากกว่า 0 (ดู docs/tickets/20-b2b-credit.md)
class UpdateCustomerCreditUseCase
    implements UseCase<Customer, UpdateCustomerCreditParams> {
  const UpdateCustomerCreditUseCase(this._repository);

  final CustomerRepository _repository;

  @override
  Future<Result<Customer>> call(UpdateCustomerCreditParams params) =>
      _repository.updateCredit(params.id, params.terms);
}

class CreateCustomerUseCase implements UseCase<Customer, CreateCustomerParams> {
  const CreateCustomerUseCase(this._repository);

  final CustomerRepository _repository;

  @override
  Future<Result<Customer>> call(CreateCustomerParams params) => _repository
      .create(name: params.name, phone: params.phone, email: params.email);
}
