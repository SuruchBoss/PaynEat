import '../../../customer/data/models/customer_model.dart';
import '../../domain/entities/receivable.dart';

/// แปลง JSON จาก /receivables/* เป็น entity — ใช้ร่วมกันทั้ง API จริงและโหมดสาธิต
class ReceivableModel {
  const ReceivableModel._();

  static double _money(Object? value) => (value as num?)?.toDouble() ?? 0;

  static AgingBuckets agingFromJson(Map<String, dynamic>? json) {
    final data = json ?? const {};
    return AgingBuckets(
      current: _money(data['current']),
      days1to30: _money(data['days1to30']),
      days31to60: _money(data['days31to60']),
      days61to90: _money(data['days61to90']),
      over90: _money(data['over90']),
    );
  }

  static ReceivableSummary summaryFromJson(Map<String, dynamic> json) =>
      ReceivableSummary(
        customer: CustomerModel.fromJson(
          (json['customer'] as Map).cast<String, dynamic>(),
        ),
        creditLimit: _money(json['creditLimit']),
        creditTermDays: (json['creditTermDays'] as num?)?.toInt() ?? 30,
        outstanding: _money(json['outstanding']),
        overdue: _money(json['overdue']),
        available: _money(json['available']),
        openInvoiceCount: (json['openInvoiceCount'] as num?)?.toInt() ?? 0,
        oldestDueDate: json['oldestDueDate'] as String?,
        aging: agingFromJson((json['aging'] as Map?)?.cast<String, dynamic>()),
      );

  static CreditInvoice invoiceFromJson(Map<String, dynamic> json) =>
      CreditInvoice(
        paymentId: (json['paymentId'] as num).toInt(),
        orderId: (json['orderId'] as num?)?.toInt() ?? 0,
        orderCode: json['orderCode'] as String? ?? '',
        amount: _money(json['amount']),
        refunded: _money(json['refunded']),
        settled: _money(json['settled']),
        outstanding: _money(json['outstanding']),
        createdAt: json['createdAt'] as String?,
        dueDate: json['dueDate'] as String?,
        daysOverdue: (json['daysOverdue'] as num?)?.toInt() ?? 0,
        billingNoteNo: json['billingNoteNo'] as String?,
      );

  static DocumentLine lineFromJson(Map<String, dynamic> json) => DocumentLine(
    paymentId: (json['paymentId'] as num).toInt(),
    orderCode: json['orderCode'] as String? ?? '',
    amount: _money(json['amount']),
    createdAt: json['createdAt'] as String?,
    dueDate: json['dueDate'] as String?,
  );

  static DocumentStoreInfo? _storeFromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, dynamic>();
    return DocumentStoreInfo(
      name: json['name'] as String? ?? '',
      taxId: json['taxId'] as String?,
      address: json['address'] as String?,
      branch: json['branch'] as String?,
    );
  }

  static List<DocumentLine> _lines(Object? raw) => (raw as List? ?? const [])
      .whereType<Map>()
      .map((row) => lineFromJson(row.cast<String, dynamic>()))
      .toList(growable: false);

  static ArReceipt receiptFromJson(Map<String, dynamic> json) => ArReceipt(
    id: (json['id'] as num).toInt(),
    receiptNo: json['receiptNo'] as String? ?? '',
    customerId: (json['customerId'] as num?)?.toInt() ?? 0,
    customerName: json['customerName'] as String? ?? '',
    amount: _money(json['amount']),
    method: json['method'] as String? ?? 'cash',
    reference: json['reference'] as String?,
    note: json['note'] as String?,
    shiftId: (json['shiftId'] as num?)?.toInt(),
    receivedByName: json['receivedByName'] as String?,
    receivedAt: json['receivedAt'] as String?,
    isVoided: json['isVoided'] as bool? ?? false,
    voidReason: json['voidReason'] as String?,
    allocations: _lines(json['allocations']),
    store: _storeFromJson(json['store']),
    customer: json['customer'] is Map
        ? CustomerModel.fromJson(
            (json['customer'] as Map).cast<String, dynamic>(),
          )
        : null,
  );

  static BillingNote billingNoteFromJson(Map<String, dynamic> json) =>
      BillingNote(
        id: (json['id'] as num).toInt(),
        noteNo: json['noteNo'] as String? ?? '',
        customerId: (json['customerId'] as num?)?.toInt() ?? 0,
        customerName: json['customerName'] as String? ?? '',
        total: _money(json['total']),
        remaining: _money(json['remaining']),
        status: json['status'] as String? ?? BillingNoteStatus.open,
        dueDate: json['dueDate'] as String? ?? '',
        note: json['note'] as String?,
        issuedByName: json['issuedByName'] as String?,
        issuedAt: json['issuedAt'] as String?,
        isVoided: json['isVoided'] as bool? ?? false,
        voidReason: json['voidReason'] as String?,
        items: _lines(json['items']),
        store: _storeFromJson(json['store']),
        customer: json['customer'] is Map
            ? CustomerModel.fromJson(
                (json['customer'] as Map).cast<String, dynamic>(),
              )
            : null,
      );

  static CustomerStatement statementFromJson(Map<String, dynamic> json) =>
      CustomerStatement(
        summary: summaryFromJson(json),
        today: json['today'] as String? ?? '',
        invoices: (json['invoices'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => invoiceFromJson(row.cast<String, dynamic>()))
            .toList(growable: false),
        receipts: (json['receipts'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => receiptFromJson(row.cast<String, dynamic>()))
            .toList(growable: false),
        billingNotes: (json['billingNotes'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => billingNoteFromJson(row.cast<String, dynamic>()))
            .toList(growable: false),
      );
}
