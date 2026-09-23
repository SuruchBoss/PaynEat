import '../../../customer/data/models/customer_model.dart';
import '../../../customer/domain/entities/customer.dart';
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
        interest: _money(json['interest']),
        interestThrough: json['interestThrough'] as String?,
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

  static Customer? _customerFromJson(Object? raw) =>
      raw is Map ? CustomerModel.fromJson(raw.cast<String, dynamic>()) : null;

  static List<Map<String, dynamic>> _maps(Object? raw) =>
      (raw as List? ?? const [])
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList(growable: false);

  static DocumentEmail emailFromJson(Map<String, dynamic> json) =>
      DocumentEmail(
        to: json['to'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        sentByName: json['sentByName'] as String?,
        sentAt: json['sentAt'] as String?,
      );

  static List<DocumentEmail> emailsFromJson(Object? raw) =>
      _maps(raw).map(emailFromJson).toList(growable: false);

  static LateFeeLine lateFeeLineFromJson(Map<String, dynamic> json) =>
      LateFeeLine(
        paymentId: (json['paymentId'] as num).toInt(),
        orderCode: json['orderCode'] as String? ?? '',
        dueDate: json['dueDate'] as String?,
        principal: _money(json['principal']),
        periodFrom: json['periodFrom'] as String? ?? '',
        periodTo: json['periodTo'] as String? ?? '',
        days: (json['days'] as num?)?.toInt() ?? 0,
        amount: _money(json['amount']),
      );

  static LateFeePreview lateFeePreviewFromJson(Map<String, dynamic> json) =>
      LateFeePreview(
        annualRate: _money(json['annualRate']),
        graceDays: (json['graceDays'] as num?)?.toInt() ?? 0,
        asOf: json['asOf'] as String? ?? '',
        total: _money(json['total']),
        items: _maps(json['items']).map(lateFeeLineFromJson).toList(),
      );

  static LateFeeCharge lateFeeFromJson(Map<String, dynamic> json) =>
      LateFeeCharge(
        id: (json['id'] as num).toInt(),
        chargeNo: json['chargeNo'] as String? ?? '',
        customerId: (json['customerId'] as num?)?.toInt() ?? 0,
        customerName: json['customerName'] as String? ?? '',
        total: _money(json['total']),
        annualRate: _money(json['annualRate']),
        asOf: json['asOf'] as String? ?? '',
        note: json['note'] as String?,
        issuedByName: json['issuedByName'] as String?,
        issuedAt: json['issuedAt'] as String?,
        isVoided: json['isVoided'] as bool? ?? false,
        voidReason: json['voidReason'] as String?,
        items: _maps(json['items']).map(lateFeeLineFromJson).toList(),
        store: _storeFromJson(json['store']),
        customer: _customerFromJson(json['customer']),
        emails: emailsFromJson(json['emails']),
      );

  static CreditNote creditNoteFromJson(Map<String, dynamic> json) => CreditNote(
    id: (json['id'] as num).toInt(),
    noteNo: json['noteNo'] as String? ?? '',
    customerId: (json['customerId'] as num?)?.toInt() ?? 0,
    customerName: json['customerName'] as String? ?? '',
    paymentId: (json['paymentId'] as num?)?.toInt() ?? 0,
    orderCode: json['orderCode'] as String? ?? '',
    originalAmount: _money(json['originalAmount']),
    previousCredited: _money(json['previousCredited']),
    amount: _money(json['amount']),
    correctAmount: _money(json['correctAmount']),
    vatAmount: _money(json['vatAmount']),
    baseAmount: _money(json['baseAmount']),
    taxInvoiceNo: json['taxInvoiceNo'] as String?,
    reason: json['reason'] as String? ?? '',
    issuedByName: json['issuedByName'] as String?,
    issuedAt: json['issuedAt'] as String?,
    invoiceDate: json['invoiceDate'] as String?,
    store: _storeFromJson(json['store']),
    customer: _customerFromJson(json['customer']),
    emails: emailsFromJson(json['emails']),
  );

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
    customer: _customerFromJson(json['customer']),
    emails: emailsFromJson(json['emails']),
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
        customer: _customerFromJson(json['customer']),
        emails: emailsFromJson(json['emails']),
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
        creditNotes: _maps(
          json['creditNotes'],
        ).map(creditNoteFromJson).toList(),
        lateFees: _maps(json['lateFees']).map(lateFeeFromJson).toList(),
      );
}
