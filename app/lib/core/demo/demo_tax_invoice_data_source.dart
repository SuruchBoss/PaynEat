part of 'demo_data_sources.dart';

class DemoTaxInvoiceDataSource implements TaxInvoiceRemoteDataSource {
  DemoTaxInvoiceDataSource(this._store, this._auth);

  final DemoStore _store;
  final DemoAuthDataSource _auth;

  @override
  Future<TaxInvoiceModel> getByOrder(int orderId) => _delayed(
    () => TaxInvoiceModel.fromJson(_store.taxInvoiceForOrder(orderId)),
  );

  @override
  Future<TaxInvoiceModel> issue(int orderId, Map<String, dynamic> body) =>
      _delayed(
        () => TaxInvoiceModel.fromJson(
          _store.issueTaxInvoice(
            orderId,
            body,
            issuedById: _auth.currentUserId,
          ),
        ),
      );

  @override
  Future<TaxInvoiceModel> voidInvoice(int orderId, String reason) => _delayed(
    () => TaxInvoiceModel.fromJson(
      _store.voidTaxInvoice(orderId, reason, voidedById: _auth.currentUserId),
    ),
  );
}
