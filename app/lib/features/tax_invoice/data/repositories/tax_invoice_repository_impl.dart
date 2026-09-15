import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/tax_invoice.dart';
import '../../domain/repositories/tax_invoice_repository.dart';
import '../datasources/tax_invoice_remote_data_source.dart';

class TaxInvoiceRepositoryImpl implements TaxInvoiceRepository {
  const TaxInvoiceRepositoryImpl(this._remote);

  final TaxInvoiceRemoteDataSource _remote;

  @override
  Future<Result<TaxInvoice>> getByOrder(int orderId) =>
      guard(() => _remote.getByOrder(orderId));

  @override
  Future<Result<TaxInvoice>> issue(int orderId, Map<String, dynamic> payload) =>
      guard(() => _remote.issue(orderId, payload));

  @override
  Future<Result<TaxInvoice>> voidInvoice(int orderId, String reason) =>
      guard(() => _remote.voidInvoice(orderId, reason));
}
