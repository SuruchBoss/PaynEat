import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/receivable.dart';
import '../../domain/repositories/receivable_repository.dart';
import '../datasources/receivable_remote_data_source.dart';

class ReceivableRepositoryImpl implements ReceivableRepository {
  const ReceivableRepositoryImpl(this._remote);

  final ReceivableRemoteDataSource _remote;

  @override
  Future<Result<List<ReceivableSummary>>> listCustomers() =>
      guard(_remote.listCustomers);

  @override
  Future<Result<CustomerStatement>> statement(int customerId) =>
      guard(() => _remote.statement(customerId));

  @override
  Future<Result<ArReceipt>> createReceipt(CreateReceiptParams params) =>
      guard(() => _remote.createReceipt(params));

  @override
  Future<Result<ArReceipt>> getReceipt(int id) =>
      guard(() => _remote.getReceipt(id));

  @override
  Future<Result<ArReceipt>> voidReceipt(int id, String reason) =>
      guard(() => _remote.voidReceipt(id, reason));

  @override
  Future<Result<BillingNote>> createBillingNote(
    CreateBillingNoteParams params,
  ) => guard(() => _remote.createBillingNote(params));

  @override
  Future<Result<BillingNote>> getBillingNote(int id) =>
      guard(() => _remote.getBillingNote(id));

  @override
  Future<Result<BillingNote>> voidBillingNote(int id, String reason) =>
      guard(() => _remote.voidBillingNote(id, reason));
}
