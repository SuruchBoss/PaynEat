// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../customer/domain/entities/customer.dart';

/// ลูกหนี้การค้า / ขายเชื่อ (ดู docs/tickets/20-b2b-credit.md, docs/DECISIONS.md #50)
///
/// "บิลขายเชื่อ" หนึ่งใบคือการชำระเงินวิธี credit หนึ่งรายการ — ยอดค้างคำนวณสดจากยอดบิล − คืนเงิน
/// − ยอดที่ตัดชำระด้วยใบเสร็จที่ยังไม่ถูกยกเลิก

/// ยอดค้างแยกตามอายุหนี้ (วันที่เกินกำหนด)
class AgingBuckets {
  const AgingBuckets({
    this.current = 0,
    this.days1to30 = 0,
    this.days31to60 = 0,
    this.days61to90 = 0,
    this.over90 = 0,
  });

  /// ยังไม่ถึงกำหนด
  final double current;
  final double days1to30;
  final double days31to60;
  final double days61to90;
  final double over90;
}

/// สรุปบัญชีลูกหนี้ของลูกค้าหนึ่งราย — แถวในหน้ารายชื่อลูกหนี้
class ReceivableSummary {
  const ReceivableSummary({
    required this.customer,
    required this.creditLimit,
    required this.creditTermDays,
    required this.outstanding,
    required this.overdue,
    required this.available,
    this.openInvoiceCount = 0,
    this.oldestDueDate,
    this.aging = const AgingBuckets(),
  });

  final Customer customer;
  final double creditLimit;
  final int creditTermDays;
  final double outstanding;
  final double overdue;
  final double available;
  final int openInvoiceCount;
  final String? oldestDueDate;
  final AgingBuckets aging;

  bool get hasOverdue => overdue > 0;
}

/// บิลขายเชื่อหนึ่งใบ
class CreditInvoice {
  const CreditInvoice({
    required this.paymentId,
    required this.orderId,
    required this.orderCode,
    required this.amount,
    required this.outstanding,
    this.refunded = 0,
    this.settled = 0,
    this.createdAt,
    this.dueDate,
    this.daysOverdue = 0,
    this.billingNoteNo,
    this.interest = 0,
    this.interestThrough,
  });

  final int paymentId;
  final int orderId;
  final String orderCode;
  final double amount;
  final double refunded;
  final double settled;
  final double outstanding;

  /// ดอกเบี้ยผิดนัดที่คิดเพิ่มในบิลนี้แล้ว (รวมอยู่ใน [outstanding]) และคิดไปถึงวันไหน
  /// (ดู docs/tickets/21-late-fees-credit-notes.md, docs/DECISIONS.md #55)
  final double interest;
  final String? interestThrough;
  final String? createdAt;
  final String? dueDate;
  final int daysOverdue;

  /// เลขที่ใบวางบิลที่บิลนี้อยู่ (ถ้ามี) — บิลหนึ่งอยู่ในใบวางบิลที่ยังไม่ถูกยกเลิกได้ใบเดียว
  final String? billingNoteNo;

  bool get isOpen => outstanding > 0;
  bool get isOverdue => daysOverdue > 0;
}

/// บรรทัดในเอกสาร (ใบวางบิล/ใบเสร็จ) อ้างถึงบิลขายเชื่อ
class DocumentLine {
  const DocumentLine({
    required this.paymentId,
    required this.orderCode,
    required this.amount,
    this.createdAt,
    this.dueDate,
  });

  final int paymentId;
  final String orderCode;
  final double amount;
  final String? createdAt;
  final String? dueDate;
}

/// หัวเอกสาร — ข้อมูลร้าน ณ ตอนพิมพ์
class DocumentStoreInfo {
  const DocumentStoreInfo({
    required this.name,
    this.taxId,
    this.address,
    this.branch,
  });

  final String name;
  final String? taxId;
  final String? address;
  final String? branch;
}

/// ประวัติการส่งเอกสารทางอีเมล (ดู docs/tickets/23-document-pdf-email.md)
class DocumentEmail {
  const DocumentEmail({
    required this.to,
    required this.subject,
    this.sentByName,
    this.sentAt,
  });

  final String to;
  final String subject;
  final String? sentByName;
  final String? sentAt;
}

/// ชนิดเอกสารลูกหนี้ที่ดาวน์โหลด PDF/ส่งอีเมลได้ — [path] ตรงกับ `/receivables/{path}/:id/pdf`
enum ReceivableDocumentKind {
  billingNote('billing-notes'),
  receipt('receipts'),
  creditNote('credit-notes'),
  lateFee('late-fees');

  const ReceivableDocumentKind(this.path);

  final String path;
}

/// ใบเสร็จรับชำระหนี้
class ArReceipt {
  const ArReceipt({
    required this.id,
    required this.receiptNo,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.method,
    this.reference,
    this.note,
    this.shiftId,
    this.receivedByName,
    this.receivedAt,
    this.isVoided = false,
    this.voidReason,
    this.allocations = const [],
    this.store,
    this.customer,
    this.emails = const [],
  });

  final int id;
  final String receiptNo;
  final int customerId;
  final String customerName;
  final double amount;
  final String method;
  final String? reference;
  final String? note;
  final int? shiftId;
  final String? receivedByName;
  final String? receivedAt;
  final bool isVoided;
  final String? voidReason;

  /// บิลที่ใบเสร็จนี้ตัดชำระ (เก่าสุดก่อน)
  final List<DocumentLine> allocations;

  /// มีเฉพาะตอนดึงแบบเอกสารเต็ม (GET /receivables/receipts/:id)
  final DocumentStoreInfo? store;
  final Customer? customer;
  final List<DocumentEmail> emails;
}

/// สถานะใบวางบิล — คำนวณจากยอดที่ยังต้องเก็บ ณ ตอนนี้
class BillingNoteStatus {
  const BillingNoteStatus._();

  static const String open = 'open';
  static const String paid = 'paid';
  static const String voided = 'void';
}

/// ใบวางบิล
class BillingNote {
  const BillingNote({
    required this.id,
    required this.noteNo,
    required this.customerId,
    required this.customerName,
    required this.total,
    required this.remaining,
    required this.status,
    required this.dueDate,
    this.note,
    this.issuedByName,
    this.issuedAt,
    this.isVoided = false,
    this.voidReason,
    this.items = const [],
    this.store,
    this.customer,
    this.emails = const [],
  });

  final int id;
  final String noteNo;
  final int customerId;
  final String customerName;

  /// ยอด ณ วันที่ออก (พิมพ์ซ้ำได้ตัวเลขเดิมเสมอ)
  final double total;

  /// ยอดที่ยังต้องเก็บตอนนี้ (ลดลงตามที่รับชำระ/คืนเงิน)
  final double remaining;
  final String status;
  final String dueDate;
  final String? note;
  final String? issuedByName;
  final String? issuedAt;
  final bool isVoided;
  final String? voidReason;
  final List<DocumentLine> items;
  final DocumentStoreInfo? store;
  final Customer? customer;
  final List<DocumentEmail> emails;

  bool get isOpen => status == BillingNoteStatus.open;
}

/// บรรทัดดอกเบี้ยของบิลหนึ่งใบ: เงินต้นค้าง × อัตรา × จำนวนวัน ÷ 365 (ดู docs/DECISIONS.md #55)
class LateFeeLine {
  const LateFeeLine({
    required this.paymentId,
    required this.orderCode,
    required this.principal,
    required this.periodFrom,
    required this.periodTo,
    required this.days,
    required this.amount,
    this.dueDate,
  });

  final int paymentId;
  final String orderCode;
  final String? dueDate;
  final double principal;
  final String periodFrom;
  final String periodTo;
  final int days;
  final double amount;
}

/// ดอกเบี้ยที่จะคิดถ้ากดออกใบแจ้งตอนนี้ (ยังไม่บันทึก)
class LateFeePreview {
  const LateFeePreview({
    required this.annualRate,
    required this.graceDays,
    required this.asOf,
    required this.total,
    this.items = const [],
  });

  final double annualRate;
  final int graceDays;
  final String asOf;
  final double total;
  final List<LateFeeLine> items;

  bool get isRateSet => annualRate > 0;
}

/// ใบแจ้งดอกเบี้ยผิดนัด — ยอดในใบบวกเข้ายอดค้างของแต่ละบิลทันที
class LateFeeCharge {
  const LateFeeCharge({
    required this.id,
    required this.chargeNo,
    required this.customerId,
    required this.customerName,
    required this.total,
    required this.annualRate,
    required this.asOf,
    this.note,
    this.issuedByName,
    this.issuedAt,
    this.isVoided = false,
    this.voidReason,
    this.items = const [],
    this.store,
    this.customer,
    this.emails = const [],
  });

  final int id;
  final String chargeNo;
  final int customerId;
  final String customerName;
  final double total;
  final double annualRate;
  final String asOf;
  final String? note;
  final String? issuedByName;
  final String? issuedAt;
  final bool isVoided;
  final String? voidReason;
  final List<LateFeeLine> items;
  final DocumentStoreInfo? store;
  final Customer? customer;
  final List<DocumentEmail> emails;
}

/// ใบลดหนี้ — ออกให้อัตโนมัติทุกครั้งที่ลดหนี้บิลขายเชื่อ (ดู docs/DECISIONS.md #56)
class CreditNote {
  const CreditNote({
    required this.id,
    required this.noteNo,
    required this.customerId,
    required this.customerName,
    required this.paymentId,
    required this.orderCode,
    required this.originalAmount,
    required this.amount,
    required this.correctAmount,
    required this.reason,
    this.previousCredited = 0,
    this.vatAmount = 0,
    this.baseAmount = 0,
    this.taxInvoiceNo,
    this.issuedByName,
    this.issuedAt,
    this.invoiceDate,
    this.store,
    this.customer,
    this.emails = const [],
  });

  final int id;
  final String noteNo;
  final int customerId;
  final String customerName;
  final int paymentId;
  final String orderCode;

  /// มูลค่าตามบิลเดิม / ลดหนี้ไปแล้วก่อนหน้า / มูลค่าที่ถูกต้องหลังลดครั้งนี้ / ผลต่าง (ครั้งนี้)
  final double originalAmount;
  final double previousCredited;
  final double correctAmount;
  final double amount;

  /// VAT ของผลต่าง (ราคาขายรวม VAT แล้ว) และมูลค่าก่อน VAT
  final double vatAmount;
  final double baseAmount;

  /// เลขใบกำกับภาษีเดิมที่ใบลดหนี้นี้อ้างถึง (ถ้าบิลนั้นเคยออกใบกำกับภาษี)
  final String? taxInvoiceNo;
  final String reason;
  final String? issuedByName;
  final String? issuedAt;
  final String? invoiceDate;
  final DocumentStoreInfo? store;
  final Customer? customer;
  final List<DocumentEmail> emails;
}

/// รายการเดินบัญชีของลูกค้าหนึ่งราย
class CustomerStatement {
  const CustomerStatement({
    required this.summary,
    required this.today,
    this.invoices = const [],
    this.receipts = const [],
    this.billingNotes = const [],
    this.creditNotes = const [],
    this.lateFees = const [],
  });

  final ReceivableSummary summary;
  final String today;
  final List<CreditInvoice> invoices;
  final List<ArReceipt> receipts;
  final List<BillingNote> billingNotes;
  final List<CreditNote> creditNotes;
  final List<LateFeeCharge> lateFees;

  List<CreditInvoice> get openInvoices =>
      invoices.where((invoice) => invoice.isOpen).toList(growable: false);

  /// บิลค้างที่ยังไม่อยู่ในใบวางบิลใด — ถ้าว่าง ปุ่ม "ออกใบวางบิล" ไม่มีอะไรให้รวบ
  List<CreditInvoice> get unbilledInvoices => openInvoices
      .where((invoice) => invoice.billingNoteNo == null)
      .toList(growable: false);

  List<BillingNote> get openBillingNotes =>
      billingNotes.where((note) => note.isOpen).toList(growable: false);
}
