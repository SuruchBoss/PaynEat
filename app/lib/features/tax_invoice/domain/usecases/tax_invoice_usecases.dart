import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/tax_invoice.dart';
import '../repositories/tax_invoice_repository.dart';

class GetTaxInvoiceUseCase implements UseCase<TaxInvoice, int> {
  const GetTaxInvoiceUseCase(this._repository);

  final TaxInvoiceRepository _repository;

  @override
  Future<Result<TaxInvoice>> call(int orderId) =>
      _repository.getByOrder(orderId);
}

/// ข้อมูลจากฟอร์มขอใบกำกับภาษี — customerName/customerAddress บังคับเฉพาะแบบเต็มรูป
/// (ดู docs/tickets/07-tax-invoice.md) ส่วนเลขผู้เสียภาษีลูกค้าไม่บังคับแม้เป็นเต็มรูป
class IssueTaxInvoiceParams {
  const IssueTaxInvoiceParams({
    required this.orderId,
    required this.invoiceType,
    this.customerName,
    this.customerAddress,
    this.customerTaxId,
  });

  final int orderId;
  final String invoiceType;
  final String? customerName;
  final String? customerAddress;
  final String? customerTaxId;

  Map<String, dynamic> toJson() => {
    'invoiceType': invoiceType,
    if (customerName != null && customerName!.isNotEmpty)
      'customerName': customerName,
    if (customerAddress != null && customerAddress!.isNotEmpty)
      'customerAddress': customerAddress,
    if (customerTaxId != null && customerTaxId!.isNotEmpty)
      'customerTaxId': customerTaxId,
  };
}

class IssueTaxInvoiceUseCase
    implements UseCase<TaxInvoice, IssueTaxInvoiceParams> {
  const IssueTaxInvoiceUseCase(this._repository);

  final TaxInvoiceRepository _repository;

  @override
  Future<Result<TaxInvoice>> call(IssueTaxInvoiceParams params) =>
      _repository.issue(params.orderId, params.toJson());
}

class VoidTaxInvoiceParams {
  const VoidTaxInvoiceParams({required this.orderId, required this.reason});

  final int orderId;
  final String reason;
}

class VoidTaxInvoiceUseCase
    implements UseCase<TaxInvoice, VoidTaxInvoiceParams> {
  const VoidTaxInvoiceUseCase(this._repository);

  final TaxInvoiceRepository _repository;

  @override
  Future<Result<TaxInvoice>> call(VoidTaxInvoiceParams params) =>
      _repository.voidInvoice(params.orderId, params.reason);
}
