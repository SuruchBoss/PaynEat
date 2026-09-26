// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../domain/entities/receivable.dart';
import 'email_document_prompt.dart';
import 'void_reason_prompt.dart';

/// 12.0 → "12", 7.5 → "7.5" — อัตราดอกเบี้ยไม่ต้องมีศูนย์ท้าย
String percentText(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

/// ปุ่ม PDF/อีเมลของเอกสาร (ticket 23) — ส่งเป็น null = ไม่แสดงปุ่มนั้น
class DocumentActions {
  const DocumentActions({this.downloadPdf, this.email});

  final Future<void> Function()? downloadPdf;

  /// ส่งอีเมล คืนประวัติการส่งล่าสุด (null = ส่งไม่สำเร็จ)
  final Future<List<DocumentEmail>?> Function({String? to, String? message})?
  email;
}

/// บรรทัดในเอกสาร — ใบวางบิล/ใบเสร็จอ้างบิลขายเชื่อ ใบแจ้งดอกเบี้ยบอกช่วงวันที่คิด ใบลดหนี้บอกมูลค่า
class ReceivableDocumentLine {
  const ReceivableDocumentLine(this.title, this.subtitle, this.amount);

  final String title;
  final String? subtitle;
  final double amount;
}

/// แสดงเอกสารลูกหนี้ทุกชนิด (ใบวางบิล ใบเสร็จรับชำระ ใบลดหนี้ ใบแจ้งดอกเบี้ยผิดนัด) — หัวร้าน,
/// ลูกค้า (ชื่อ/เลขผู้เสียภาษี/ที่อยู่), รายการ และยอดรวม พร้อมปุ่มดาวน์โหลด PDF/ส่งอีเมล และประวัติ
/// การส่ง คืนเหตุผลยกเลิกถ้าผู้จัดการกดยกเลิกเอกสารนี้ (null = แค่ปิดดู)
/// (ดู docs/tickets/20-b2b-credit.md, 21-late-fees-credit-notes.md, 23-document-pdf-email.md)
class ReceivableDocumentDialog extends StatefulWidget {
  const ReceivableDocumentDialog._({
    required this.title,
    required this.number,
    required this.issuedAt,
    required this.store,
    required this.customer,
    required this.customerName,
    required this.lines,
    required this.totalLabel,
    required this.total,
    required this.isVoided,
    required this.canVoid,
    required this.voidTitle,
    required this.emails,
    required this.actions,
    this.voidReason,
    this.extraRows = const [],
    this.notes = const [],
    this.footer,
  });

  final String title;
  final String number;
  final String? issuedAt;
  final DocumentStoreInfo? store;
  final Customer? customer;
  final String customerName;
  final List<ReceivableDocumentLine> lines;
  final String totalLabel;
  final double total;
  final bool isVoided;
  final String? voidReason;

  /// null = เอกสารชนิดนี้ยกเลิกไม่ได้ (ใบลดหนี้ — แก้ด้วยการออกใบใหม่)
  final bool canVoid;
  final String voidTitle;
  final List<(String, String)> extraRows;
  final List<String> notes;
  final String? footer;
  final List<DocumentEmail> emails;
  final DocumentActions actions;

  static String _dates(String? createdAt, String? dueDate) =>
      'receivable_line_dates'.trParams({
        'date': Formatters.dateTime(createdAt),
        'due': Formatters.dueDate(dueDate),
      });

  static List<ReceivableDocumentLine> _documentLines(
    List<DocumentLine> lines,
  ) => [
    for (final line in lines)
      ReceivableDocumentLine(
        '#${line.orderCode}',
        _dates(line.createdAt, line.dueDate),
        line.amount,
      ),
  ];

  static Future<String?> showBillingNote(
    BillingNote note, {
    required bool canVoid,
    DocumentActions actions = const DocumentActions(),
  }) => Get.dialog<String>(
    ReceivableDocumentDialog._(
      title: 'receivable_billing_note_title'.tr,
      number: note.noteNo,
      issuedAt: note.issuedAt,
      store: note.store,
      customer: note.customer,
      customerName: note.customerName,
      lines: _documentLines(note.items),
      totalLabel: 'receivable_billing_note_total'.tr,
      total: note.total,
      isVoided: note.isVoided,
      voidReason: note.voidReason,
      canVoid: canVoid,
      voidTitle: 'receivable_billing_note_void_title'.tr,
      extraRows: [
        (
          'receivable_billing_note_due_date'.tr,
          Formatters.dueDate(note.dueDate),
        ),
        if (!note.isVoided)
          (
            'receivable_billing_note_remaining'.tr,
            Formatters.baht(note.remaining),
          ),
      ],
      footer: note.issuedByName == null
          ? null
          : 'receivable_document_issued_by'.trParams({
              'name': note.issuedByName!,
            }),
      emails: note.emails,
      actions: actions,
    ),
  );

  static Future<String?> showReceipt(
    ArReceipt receipt, {
    required bool canVoid,
    DocumentActions actions = const DocumentActions(),
  }) => Get.dialog<String>(
    ReceivableDocumentDialog._(
      title: 'receivable_receipt_title'.tr,
      number: receipt.receiptNo,
      issuedAt: receipt.receivedAt,
      store: receipt.store,
      customer: receipt.customer,
      customerName: receipt.customerName,
      lines: _documentLines(receipt.allocations),
      totalLabel: 'receivable_receipt_total'.tr,
      total: receipt.amount,
      isVoided: receipt.isVoided,
      voidReason: receipt.voidReason,
      canVoid: canVoid,
      voidTitle: 'receivable_receipt_void_title'.tr,
      extraRows: [
        ('receivable_receipt_method'.tr, PaymentMethod.label(receipt.method)),
        if (receipt.reference != null && receipt.reference!.isNotEmpty)
          ('receivable_receipt_reference'.tr, receipt.reference!),
      ],
      footer: receipt.receivedByName == null
          ? null
          : 'receivable_document_received_by'.trParams({
              'name': receipt.receivedByName!,
            }),
      emails: receipt.emails,
      actions: actions,
    ),
  );

  static Future<String?> showLateFee(
    LateFeeCharge charge, {
    required bool canVoid,
    DocumentActions actions = const DocumentActions(),
  }) => Get.dialog<String>(
    ReceivableDocumentDialog._(
      title: 'receivable_late_fee_title'.tr,
      number: charge.chargeNo,
      issuedAt: charge.issuedAt,
      store: charge.store,
      customer: charge.customer,
      customerName: charge.customerName,
      lines: [for (final line in charge.items) _lateFeeLine(line)],
      totalLabel: 'receivable_late_fee_total'.tr,
      total: charge.total,
      isVoided: charge.isVoided,
      voidReason: charge.voidReason,
      canVoid: canVoid,
      voidTitle: 'receivable_late_fee_void_title'.tr,
      extraRows: [
        (
          'receivable_late_fee_rate'.tr,
          'receivable_late_fee_rate_value'.trParams({
            'rate': percentText(charge.annualRate),
          }),
        ),
        ('receivable_late_fee_as_of'.tr, Formatters.dueDate(charge.asOf)),
      ],
      notes: [
        if (charge.note != null && charge.note!.isNotEmpty) charge.note!,
        'receivable_late_fee_formula'.tr,
      ],
      footer: charge.issuedByName == null
          ? null
          : 'receivable_document_issued_by'.trParams({
              'name': charge.issuedByName!,
            }),
      emails: charge.emails,
      actions: actions,
    ),
  );

  static ReceivableDocumentLine _lateFeeLine(LateFeeLine line) =>
      ReceivableDocumentLine(
        '#${line.orderCode}',
        'receivable_late_fee_line'.trParams({
          'from': Formatters.dueDate(line.periodFrom),
          'to': Formatters.dueDate(line.periodTo),
          'days': '${line.days}',
          'principal': Formatters.money(line.principal),
        }),
        line.amount,
      );

  /// ใบลดหนี้ยกเลิกไม่ได้ — ลดผิดให้รับชำระ/ออกบิลใหม่แทน (เหมือนใบกำกับภาษีที่ต้องมีต้นขั้ว)
  static Future<void> showCreditNote(
    CreditNote note, {
    DocumentActions actions = const DocumentActions(),
  }) => Get.dialog<void>(
    ReceivableDocumentDialog._(
      title: 'receivable_credit_note_title'.tr,
      number: note.noteNo,
      issuedAt: note.issuedAt,
      store: note.store,
      customer: note.customer,
      customerName: note.customerName,
      lines: [
        ReceivableDocumentLine(
          'receivable_credit_note_original'.trParams({'code': note.orderCode}),
          note.invoiceDate == null
              ? null
              : Formatters.dateTime(note.invoiceDate),
          note.originalAmount,
        ),
        if (note.previousCredited > 0)
          ReceivableDocumentLine(
            'receivable_credit_note_previous'.tr,
            null,
            note.previousCredited,
          ),
        ReceivableDocumentLine(
          'receivable_credit_note_correct'.tr,
          null,
          note.correctAmount,
        ),
      ],
      totalLabel: 'receivable_credit_note_total'.tr,
      total: note.amount,
      isVoided: false,
      canVoid: false,
      voidTitle: '',
      extraRows: [
        if (note.taxInvoiceNo != null)
          ('receivable_credit_note_tax_invoice'.tr, note.taxInvoiceNo!),
        ('receivable_credit_note_base'.tr, Formatters.baht(note.baseAmount)),
        ('receivable_credit_note_vat'.tr, Formatters.baht(note.vatAmount)),
      ],
      notes: [
        'receivable_credit_note_reason'.trParams({'reason': note.reason}),
      ],
      footer: note.issuedByName == null
          ? null
          : 'receivable_document_issued_by'.trParams({
              'name': note.issuedByName!,
            }),
      emails: note.emails,
      actions: actions,
    ),
  );

  @override
  State<ReceivableDocumentDialog> createState() =>
      _ReceivableDocumentDialogState();
}

class _ReceivableDocumentDialogState extends State<ReceivableDocumentDialog> {
  late List<DocumentEmail> _emails = widget.emails;
  bool _busy = false;

  Future<void> _download() async {
    setState(() => _busy = true);
    await widget.actions.downloadPdf!();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _email() async {
    final input = await EmailDocumentPrompt.show(
      initialTo: widget.customer?.email,
      documentNo: widget.number,
    );
    if (input == null) return;
    setState(() => _busy = true);
    final emails = await widget.actions.email!(
      to: input.to,
      message: input.message,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (emails != null) _emails = emails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final secondary = TextStyle(fontSize: 12.5, color: AppColors.textSecondary);
    final canEmail = widget.actions.email != null && !widget.isVoided;
    final canDownload = widget.actions.downloadPdf != null;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isVoided) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.voidReason == null
                        ? 'receivable_document_voided'.tr
                        : '${'receivable_document_voided'.tr} — ${widget.voidReason}',
                    style: TextStyle(
                      color: AppColors.dangerInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _Row(
                label: 'receivable_document_no'.tr,
                value: widget.number,
                bold: true,
              ),
              _Row(
                label: 'receivable_document_date'.tr,
                value: Formatters.dateTime(widget.issuedAt),
              ),
              for (final (label, value) in widget.extraRows)
                _Row(label: label, value: value),
              if (widget.store != null) ...[
                const Divider(height: 20),
                Text(
                  widget.store!.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (widget.store!.address != null)
                  Text(widget.store!.address!, style: secondary),
                if (widget.store!.taxId != null)
                  Text(
                    'tax_invoice_tax_id_value'.trParams({
                      'taxId': widget.store!.taxId!,
                    }),
                    style: secondary,
                  ),
              ],
              const Divider(height: 20),
              Text(
                'receivable_document_customer'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(widget.customerName, style: const TextStyle(fontSize: 13)),
              if (widget.customer?.address != null)
                Text(widget.customer!.address!, style: secondary),
              if (widget.customer?.taxId != null)
                Text(
                  'tax_invoice_tax_id_value'.trParams({
                    'taxId': widget.customer!.taxId!,
                  }),
                  style: secondary,
                ),
              const Divider(height: 20),
              for (final line in widget.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (line.subtitle != null)
                              Text(line.subtitle!, style: secondary),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(Formatters.money(line.amount)),
                    ],
                  ),
                ),
              const Divider(height: 20),
              _Row(
                label: widget.totalLabel,
                value: Formatters.baht(widget.total),
                bold: true,
              ),
              for (final note in widget.notes) ...[
                const SizedBox(height: 6),
                Text(note, style: secondary),
              ],
              if (widget.footer != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.footer!,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
              if (_emails.isNotEmpty) ...[
                const Divider(height: 20),
                Text(
                  'receivable_email_history'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                for (final email in _emails)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'receivable_email_history_line'.trParams({
                        'to': email.to,
                        'date': Formatters.dateTime(email.sentAt),
                        'name': email.sentByName ?? '-',
                      }),
                      key: const ValueKey('document-email-history'),
                      style: secondary,
                    ),
                  ),
              ],
              if (canDownload || canEmail) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canDownload)
                      OutlinedButton.icon(
                        key: const ValueKey('document-download-pdf'),
                        onPressed: _busy ? null : _download,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text('receivable_download_pdf'.tr),
                      ),
                    if (canEmail)
                      OutlinedButton.icon(
                        key: const ValueKey('document-send-email'),
                        onPressed: _busy ? null : _email,
                        icon: const Icon(Icons.forward_to_inbox_outlined),
                        label: Text('receivable_send_email'.tr),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (widget.canVoid && !widget.isVoided)
          TextButton(
            onPressed: () async {
              final reason = await promptVoidReason(widget.voidTitle);
              if (reason != null) Get.back<String>(result: reason);
            },
            child: Text(
              'receivable_void_button'.tr,
              style: TextStyle(color: AppColors.dangerInk),
            ),
          ),
        FilledButton(
          onPressed: () => Get.back<String>(),
          child: Text('common_close'.tr),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: bold ? 14 : 12.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
