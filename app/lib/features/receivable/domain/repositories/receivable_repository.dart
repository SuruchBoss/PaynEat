import '../../../../core/usecases/result.dart';
import '../entities/receivable.dart';

abstract class ReceivableRepository {
  Future<Result<List<ReceivableSummary>>> listCustomers();

  Future<Result<CustomerStatement>> statement(int customerId);

  Future<Result<ArReceipt>> createReceipt(CreateReceiptParams params);

  Future<Result<ArReceipt>> getReceipt(int id);

  Future<Result<ArReceipt>> voidReceipt(int id, String reason);

  Future<Result<BillingNote>> createBillingNote(CreateBillingNoteParams params);

  Future<Result<BillingNote>> getBillingNote(int id);

  Future<Result<BillingNote>> voidBillingNote(int id, String reason);
}

/// รับชำระหนี้ — ไม่ระบุ [billingNoteId] = ตัดบิลเก่าสุดก่อน
class CreateReceiptParams {
  const CreateReceiptParams({
    required this.customerId,
    required this.amount,
    required this.method,
    this.reference,
    this.note,
    this.billingNoteId,
  });

  final int customerId;
  final double amount;
  final String method;
  final String? reference;
  final String? note;
  final int? billingNoteId;

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'amount': amount,
    'method': method,
    if (reference != null && reference!.isNotEmpty) 'reference': reference,
    if (note != null && note!.isNotEmpty) 'note': note,
    'billingNoteId': ?billingNoteId,
  };
}

/// ออกใบวางบิล — ไม่ระบุ [paymentIds] = รวบทุกบิลค้างที่ยังไม่ได้วางบิล
class CreateBillingNoteParams {
  const CreateBillingNoteParams({
    required this.customerId,
    this.paymentIds,
    this.dueDate,
    this.note,
  });

  final int customerId;
  final List<int>? paymentIds;
  final String? dueDate;
  final String? note;

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    if (paymentIds != null && paymentIds!.isNotEmpty) 'paymentIds': paymentIds,
    'dueDate': ?dueDate,
    if (note != null && note!.isNotEmpty) 'note': note,
  };
}
