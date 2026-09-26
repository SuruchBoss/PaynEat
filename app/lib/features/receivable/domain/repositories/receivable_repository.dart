// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

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

  // ดอกเบี้ยผิดนัด / ใบลดหนี้ (ดู docs/tickets/21-late-fees-credit-notes.md)
  Future<Result<LateFeePreview>> previewLateFee(int customerId);

  Future<Result<LateFeeCharge>> createLateFee(int customerId, {String? note});

  Future<Result<LateFeeCharge>> getLateFee(int id);

  Future<Result<LateFeeCharge>> voidLateFee(int id, String reason);

  Future<Result<CreditNote>> createCreditNote(CreateCreditNoteParams params);

  Future<Result<CreditNote>> getCreditNote(int id);

  // PDF + อีเมล (ดู docs/tickets/23-document-pdf-email.md)
  Future<Result<List<int>>> downloadPdf(ReceivableDocumentKind kind, int id);

  /// ส่งเอกสารทางอีเมล — คืนประวัติการส่งล่าสุดของเอกสารนั้น
  Future<Result<List<DocumentEmail>>> emailDocument(EmailDocumentParams params);
}

/// ลดหนี้บิลขายเชื่อพร้อมออกใบลดหนี้ (ผู้จัดการขึ้นไป)
class CreateCreditNoteParams {
  const CreateCreditNoteParams({
    required this.paymentId,
    required this.amount,
    required this.reason,
  });

  final int paymentId;
  final double amount;
  final String reason;

  Map<String, dynamic> toJson() => {
    'paymentId': paymentId,
    'amount': amount,
    'reason': reason,
  };
}

/// ส่งเอกสารเป็น PDF ทางอีเมล — ไม่ระบุ [to] = ส่งถึงอีเมลของลูกค้าในบัญชีเครดิต
class EmailDocumentParams {
  const EmailDocumentParams({
    required this.kind,
    required this.id,
    this.to,
    this.message,
  });

  final ReceivableDocumentKind kind;
  final int id;
  final String? to;
  final String? message;

  Map<String, dynamic> toJson() => {
    if (to != null && to!.trim().isNotEmpty) 'to': to!.trim(),
    if (message != null && message!.trim().isNotEmpty)
      'message': message!.trim(),
  };
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
