import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/receivable.dart';
import '../repositories/receivable_repository.dart';

class GetReceivableCustomersUseCase
    implements NoParamsUseCase<List<ReceivableSummary>> {
  const GetReceivableCustomersUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<List<ReceivableSummary>>> call() => _repository.listCustomers();
}

class GetCustomerStatementUseCase implements UseCase<CustomerStatement, int> {
  const GetCustomerStatementUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<CustomerStatement>> call(int params) =>
      _repository.statement(params);
}

class CreateArReceiptUseCase
    implements UseCase<ArReceipt, CreateReceiptParams> {
  const CreateArReceiptUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<ArReceipt>> call(CreateReceiptParams params) =>
      _repository.createReceipt(params);
}

class GetArReceiptUseCase implements UseCase<ArReceipt, int> {
  const GetArReceiptUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<ArReceipt>> call(int params) => _repository.getReceipt(params);
}

class VoidDocumentParams {
  const VoidDocumentParams({required this.id, required this.reason});

  final int id;
  final String reason;
}

class VoidArReceiptUseCase implements UseCase<ArReceipt, VoidDocumentParams> {
  const VoidArReceiptUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<ArReceipt>> call(VoidDocumentParams params) =>
      _repository.voidReceipt(params.id, params.reason);
}

class CreateBillingNoteUseCase
    implements UseCase<BillingNote, CreateBillingNoteParams> {
  const CreateBillingNoteUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<BillingNote>> call(CreateBillingNoteParams params) =>
      _repository.createBillingNote(params);
}

class GetBillingNoteUseCase implements UseCase<BillingNote, int> {
  const GetBillingNoteUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<BillingNote>> call(int params) =>
      _repository.getBillingNote(params);
}

class VoidBillingNoteUseCase
    implements UseCase<BillingNote, VoidDocumentParams> {
  const VoidBillingNoteUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<BillingNote>> call(VoidDocumentParams params) =>
      _repository.voidBillingNote(params.id, params.reason);
}
