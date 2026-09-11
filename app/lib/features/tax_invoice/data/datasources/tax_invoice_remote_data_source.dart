import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/tax_invoice_model.dart';

abstract class TaxInvoiceRemoteDataSource {
  Future<TaxInvoiceModel> getByOrder(int orderId);
  Future<TaxInvoiceModel> issue(int orderId, Map<String, dynamic> body);
  Future<TaxInvoiceModel> voidInvoice(int orderId, String reason);
}

class TaxInvoiceRemoteDataSourceImpl implements TaxInvoiceRemoteDataSource {
  const TaxInvoiceRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<TaxInvoiceModel> getByOrder(int orderId) async {
    final result = await _client.get(ApiEndpoints.taxInvoice(orderId));
    return TaxInvoiceModel.fromJson(result.asMap);
  }

  @override
  Future<TaxInvoiceModel> issue(int orderId, Map<String, dynamic> body) async {
    final result = await _client.post(
      ApiEndpoints.taxInvoice(orderId),
      body: body,
    );
    return TaxInvoiceModel.fromJson(result.asMap);
  }

  @override
  Future<TaxInvoiceModel> voidInvoice(int orderId, String reason) async {
    final result = await _client.post(
      ApiEndpoints.taxInvoiceVoid(orderId),
      body: {'reason': reason},
    );
    return TaxInvoiceModel.fromJson(result.asMap);
  }
}
