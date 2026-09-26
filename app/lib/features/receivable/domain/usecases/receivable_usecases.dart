// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

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

// ดอกเบี้ยผิดนัด / ใบลดหนี้ (ดู docs/tickets/21-late-fees-credit-notes.md)

class CreateLateFeeParams {
  const CreateLateFeeParams({required this.customerId, this.note});

  final int customerId;
  final String? note;
}

class PreviewLateFeeUseCase implements UseCase<LateFeePreview, int> {
  const PreviewLateFeeUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<LateFeePreview>> call(int params) =>
      _repository.previewLateFee(params);
}

class CreateLateFeeUseCase
    implements UseCase<LateFeeCharge, CreateLateFeeParams> {
  const CreateLateFeeUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<LateFeeCharge>> call(CreateLateFeeParams params) =>
      _repository.createLateFee(params.customerId, note: params.note);
}

class GetLateFeeUseCase implements UseCase<LateFeeCharge, int> {
  const GetLateFeeUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<LateFeeCharge>> call(int params) =>
      _repository.getLateFee(params);
}

class VoidLateFeeUseCase implements UseCase<LateFeeCharge, VoidDocumentParams> {
  const VoidLateFeeUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<LateFeeCharge>> call(VoidDocumentParams params) =>
      _repository.voidLateFee(params.id, params.reason);
}

class CreateCreditNoteUseCase
    implements UseCase<CreditNote, CreateCreditNoteParams> {
  const CreateCreditNoteUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<CreditNote>> call(CreateCreditNoteParams params) =>
      _repository.createCreditNote(params);
}

class GetCreditNoteUseCase implements UseCase<CreditNote, int> {
  const GetCreditNoteUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<CreditNote>> call(int params) =>
      _repository.getCreditNote(params);
}

// PDF + อีเมล (ดู docs/tickets/23-document-pdf-email.md)

class ReceivableDocumentRef {
  const ReceivableDocumentRef(this.kind, this.id);

  final ReceivableDocumentKind kind;
  final int id;
}

class DownloadReceivablePdfUseCase
    implements UseCase<List<int>, ReceivableDocumentRef> {
  const DownloadReceivablePdfUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<List<int>>> call(ReceivableDocumentRef params) =>
      _repository.downloadPdf(params.kind, params.id);
}

class EmailReceivableDocumentUseCase
    implements UseCase<List<DocumentEmail>, EmailDocumentParams> {
  const EmailReceivableDocumentUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<List<DocumentEmail>>> call(EmailDocumentParams params) =>
      _repository.emailDocument(params);
}
