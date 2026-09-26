// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/receivable.dart';
import '../../domain/repositories/receivable_repository.dart';
import '../models/receivable_model.dart';

abstract class ReceivableRemoteDataSource {
  Future<List<ReceivableSummary>> listCustomers();
  Future<CustomerStatement> statement(int customerId);
  Future<ArReceipt> createReceipt(CreateReceiptParams params);
  Future<ArReceipt> getReceipt(int id);
  Future<ArReceipt> voidReceipt(int id, String reason);
  Future<BillingNote> createBillingNote(CreateBillingNoteParams params);
  Future<BillingNote> getBillingNote(int id);
  Future<BillingNote> voidBillingNote(int id, String reason);
  Future<LateFeePreview> previewLateFee(int customerId);
  Future<LateFeeCharge> createLateFee(int customerId, {String? note});
  Future<LateFeeCharge> getLateFee(int id);
  Future<LateFeeCharge> voidLateFee(int id, String reason);
  Future<CreditNote> createCreditNote(CreateCreditNoteParams params);
  Future<CreditNote> getCreditNote(int id);
  Future<List<int>> downloadPdf(ReceivableDocumentKind kind, int id);
  Future<List<DocumentEmail>> emailDocument(EmailDocumentParams params);
}

class ReceivableRemoteDataSourceImpl implements ReceivableRemoteDataSource {
  const ReceivableRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<ReceivableSummary>> listCustomers() async {
    final result = await _client.get(ApiEndpoints.receivableCustomers);
    return result.asList
        .map(ReceivableModel.summaryFromJson)
        .toList(growable: false);
  }

  @override
  Future<CustomerStatement> statement(int customerId) async {
    final result = await _client.get(
      ApiEndpoints.receivableStatement(customerId),
    );
    return ReceivableModel.statementFromJson(result.asMap);
  }

  @override
  Future<ArReceipt> createReceipt(CreateReceiptParams params) async {
    final result = await _client.post(
      ApiEndpoints.arReceipts,
      body: params.toJson(),
    );
    return ReceivableModel.receiptFromJson(result.asMap);
  }

  @override
  Future<ArReceipt> getReceipt(int id) async {
    final result = await _client.get(ApiEndpoints.arReceipt(id));
    return ReceivableModel.receiptFromJson(result.asMap);
  }

  @override
  Future<ArReceipt> voidReceipt(int id, String reason) async {
    final result = await _client.post(
      ApiEndpoints.arReceiptVoid(id),
      body: {'reason': reason},
    );
    return ReceivableModel.receiptFromJson(result.asMap);
  }

  @override
  Future<BillingNote> createBillingNote(CreateBillingNoteParams params) async {
    final result = await _client.post(
      ApiEndpoints.billingNotes,
      body: params.toJson(),
    );
    return ReceivableModel.billingNoteFromJson(result.asMap);
  }

  @override
  Future<BillingNote> getBillingNote(int id) async {
    final result = await _client.get(ApiEndpoints.billingNote(id));
    return ReceivableModel.billingNoteFromJson(result.asMap);
  }

  @override
  Future<BillingNote> voidBillingNote(int id, String reason) async {
    final result = await _client.post(
      ApiEndpoints.billingNoteVoid(id),
      body: {'reason': reason},
    );
    return ReceivableModel.billingNoteFromJson(result.asMap);
  }

  @override
  Future<LateFeePreview> previewLateFee(int customerId) async {
    final result = await _client.get(ApiEndpoints.lateFeePreview(customerId));
    return ReceivableModel.lateFeePreviewFromJson(result.asMap);
  }

  @override
  Future<LateFeeCharge> createLateFee(int customerId, {String? note}) async {
    final result = await _client.post(
      ApiEndpoints.lateFees,
      body: {
        'customerId': customerId,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return ReceivableModel.lateFeeFromJson(result.asMap);
  }

  @override
  Future<LateFeeCharge> getLateFee(int id) async {
    final result = await _client.get(ApiEndpoints.lateFee(id));
    return ReceivableModel.lateFeeFromJson(result.asMap);
  }

  @override
  Future<LateFeeCharge> voidLateFee(int id, String reason) async {
    final result = await _client.post(
      ApiEndpoints.lateFeeVoid(id),
      body: {'reason': reason},
    );
    return ReceivableModel.lateFeeFromJson(result.asMap);
  }

  @override
  Future<CreditNote> createCreditNote(CreateCreditNoteParams params) async {
    final result = await _client.post(
      ApiEndpoints.creditNotes,
      body: params.toJson(),
    );
    return ReceivableModel.creditNoteFromJson(result.asMap);
  }

  @override
  Future<CreditNote> getCreditNote(int id) async {
    final result = await _client.get(ApiEndpoints.creditNote(id));
    return ReceivableModel.creditNoteFromJson(result.asMap);
  }

  @override
  Future<List<int>> downloadPdf(ReceivableDocumentKind kind, int id) =>
      _client.getBytes(ApiEndpoints.receivableDocumentPdf(kind.path, id));

  @override
  Future<List<DocumentEmail>> emailDocument(EmailDocumentParams params) async {
    final result = await _client.post(
      ApiEndpoints.receivableDocumentEmail(params.kind.path, params.id),
      body: params.toJson(),
    );
    return ReceivableModel.emailsFromJson(result.asMap['emails']);
  }
}
