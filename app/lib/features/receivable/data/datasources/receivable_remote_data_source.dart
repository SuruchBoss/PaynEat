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
}
