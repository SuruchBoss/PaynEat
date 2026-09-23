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

  /// ตั้งวงเงินเครดิต/เครดิตเทอม/ข้อมูลออกเอกสาร (ผู้จัดการขึ้นไป — ดู docs/tickets/20-b2b-credit.md)
  Future<Result<Customer>> updateCredit(int id, CustomerCreditTerms terms);
}
