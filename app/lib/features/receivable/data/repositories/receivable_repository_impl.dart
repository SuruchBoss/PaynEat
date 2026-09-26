// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

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

  @override
  Future<Result<LateFeePreview>> previewLateFee(int customerId) =>
      guard(() => _remote.previewLateFee(customerId));

  @override
  Future<Result<LateFeeCharge>> createLateFee(int customerId, {String? note}) =>
      guard(() => _remote.createLateFee(customerId, note: note));

  @override
  Future<Result<LateFeeCharge>> getLateFee(int id) =>
      guard(() => _remote.getLateFee(id));

  @override
  Future<Result<LateFeeCharge>> voidLateFee(int id, String reason) =>
      guard(() => _remote.voidLateFee(id, reason));

  @override
  Future<Result<CreditNote>> createCreditNote(CreateCreditNoteParams params) =>
      guard(() => _remote.createCreditNote(params));

  @override
  Future<Result<CreditNote>> getCreditNote(int id) =>
      guard(() => _remote.getCreditNote(id));

  @override
  Future<Result<List<int>>> downloadPdf(ReceivableDocumentKind kind, int id) =>
      guard(() => _remote.downloadPdf(kind, id));

  @override
  Future<Result<List<DocumentEmail>>> emailDocument(
    EmailDocumentParams params,
  ) => guard(() => _remote.emailDocument(params));
}
