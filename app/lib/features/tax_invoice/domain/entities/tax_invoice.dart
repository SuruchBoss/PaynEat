import '../../../../core/constants/app_constants.dart';

/// ใบกำกับภาษี — snapshot ข้อมูลร้าน+ยอดเงิน ณ เวลาที่ออก แยกจากใบเสร็จปกติ
/// (ดู docs/DECISIONS.md #19) ออกได้สูงสุด 1 ใบ "active" ต่อออเดอร์ ยกเลิกแล้วออกใหม่ได้
class TaxInvoice {
  const TaxInvoice({
    required this.id,
    required this.orderId,
    required this.runningNumber,
    required this.invoiceType,
    required this.storeName,
    required this.storeTaxId,
    required this.storeAddress,
    required this.subtotal,
    required this.vat,
    required this.total,
    required this.issuedAt,
    this.orderCode,
    this.customerName,
    this.customerAddress,
    this.customerTaxId,
    this.storeBranch,
    this.issuedByName,
    this.isVoid = false,
    this.voidedAt,
    this.voidReason,
    this.voidedByName,
  });

  final int id;
  final int orderId;
  final String? orderCode;
  final String runningNumber;
  final String invoiceType;
  final String? customerName;
  final String? customerAddress;
  final String? customerTaxId;
  final String storeName;
  final String storeTaxId;
  final String storeAddress;
  final String? storeBranch;
  final double subtotal;
  final double vat;
  final double total;
  final String? issuedByName;
  final String issuedAt;
  final bool isVoid;
  final String? voidedAt;
  final String? voidReason;
  final String? voidedByName;

  bool get isFull => invoiceType == TaxInvoiceType.full;
}
