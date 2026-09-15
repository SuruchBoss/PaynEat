import '../../../../core/usecases/result.dart';
import '../entities/tax_invoice.dart';

abstract class TaxInvoiceRepository {
  Future<Result<TaxInvoice>> getByOrder(int orderId);
  Future<Result<TaxInvoice>> issue(int orderId, Map<String, dynamic> payload);
  Future<Result<TaxInvoice>> voidInvoice(int orderId, String reason);
}
