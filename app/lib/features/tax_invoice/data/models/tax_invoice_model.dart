import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/tax_invoice.dart';

class TaxInvoiceModel extends TaxInvoice {
  const TaxInvoiceModel({
    required super.id,
    required super.orderId,
    required super.runningNumber,
    required super.invoiceType,
    required super.storeName,
    required super.storeTaxId,
    required super.storeAddress,
    required super.subtotal,
    required super.vat,
    required super.total,
    required super.issuedAt,
    super.orderCode,
    super.customerName,
    super.customerAddress,
    super.customerTaxId,
    super.storeBranch,
    super.issuedByName,
    super.isVoid,
    super.voidedAt,
    super.voidReason,
    super.voidedByName,
  });

  factory TaxInvoiceModel.fromJson(Map<String, dynamic> json) =>
      TaxInvoiceModel(
        id: (json['id'] as num).toInt(),
        orderId: (json['orderId'] as num).toInt(),
        orderCode: json['orderCode'] as String?,
        runningNumber: json['runningNumber'] as String? ?? '',
        invoiceType:
            json['invoiceType'] as String? ?? TaxInvoiceType.abbreviated,
        customerName: json['customerName'] as String?,
        customerAddress: json['customerAddress'] as String?,
        customerTaxId: json['customerTaxId'] as String?,
        storeName: json['storeName'] as String? ?? '',
        storeTaxId: json['storeTaxId'] as String? ?? '',
        storeAddress: json['storeAddress'] as String? ?? '',
        storeBranch: json['storeBranch'] as String?,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        vat: (json['vat'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        issuedByName: json['issuedByName'] as String?,
        issuedAt: json['issuedAt'] as String? ?? '',
        isVoid: json['isVoid'] as bool? ?? false,
        voidedAt: json['voidedAt'] as String?,
        voidReason: json['voidReason'] as String?,
        voidedByName: json['voidedByName'] as String?,
      );
}
