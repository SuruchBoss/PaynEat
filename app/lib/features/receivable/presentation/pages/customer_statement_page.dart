import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/receivable.dart';
import '../controllers/customer_statement_controller.dart';
import '../widgets/receivable_document_dialog.dart';
import '../widgets/receive_payment_dialog.dart';

/// รายการเดินบัญชีของลูกค้าเครดิตหนึ่งราย: ยอดค้าง/อายุหนี้, บิลขายเชื่อ, ใบวางบิล, ใบเสร็จรับชำระ
/// (ดู docs/tickets/20-b2b-credit.md)
class CustomerStatementPage extends GetView<CustomerStatementController> {
  const CustomerStatementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('receivable_statement_title'.tr)),
      body: Obx(() {
        final statement = controller.statement.value;
        if (controller.isLoading.value && statement == null) {
          return const LoadingView();
        }
        final error = controller.errorMessage.value;
        if (statement == null) {
          return ErrorView(
            message: error ?? 'customer_detail_not_found'.tr,
            onRetry: controller.load,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(summary: statement.summary),
              const SizedBox(height: 12),
              _Actions(statement: statement),
              const SizedBox(height: 18),
              _SectionTitle('receivable_invoices_title'.tr),
              if (statement.invoices.isEmpty)
                _EmptyLine('receivable_invoices_empty'.tr)
              else
                for (final invoice in statement.invoices)
                  _InvoiceTile(invoice: invoice),
              const SizedBox(height: 18),
              _SectionTitle('receivable_billing_notes_title'.tr),
              if (statement.billingNotes.isEmpty)
                _EmptyLine('receivable_billing_notes_empty'.tr)
              else
                for (final note in statement.billingNotes)
                  _BillingNoteTile(note: note),
              const SizedBox(height: 18),
              _SectionTitle('receivable_receipts_title'.tr),
              if (statement.receipts.isEmpty)
                _EmptyLine('receivable_receipts_empty'.tr)
              else
                for (final receipt in statement.receipts)
                  _ReceiptTile(receipt: receipt),
            ],
          ),
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ReceivableSummary summary;

  @override
  Widget build(BuildContext context) {
    final secondary = TextStyle(fontSize: 12.5, color: AppColors.textSecondary);
    final aging = summary.aging;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.customer.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(summary.customer.phone, style: secondary),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('receivable_outstanding_label'.tr, style: secondary),
                    Text(
                      Formatters.baht(summary.outstanding),
                      key: const ValueKey('statement-outstanding'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: summary.hasOverdue
                            ? AppColors.dangerInk
                            : AppColors.brandInk,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'receivable_available_value'.trParams({
                      'amount': Formatters.baht(summary.available),
                    }),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'receivable_limit_term_value'.trParams({
                      'limit': Formatters.baht(summary.creditLimit),
                      'days': '${summary.creditTermDays}',
                    }),
                    style: secondary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AgingChip('receivable_aging_current'.tr, aging.current, false),
              _AgingChip('receivable_aging_1_30'.tr, aging.days1to30, true),
              _AgingChip('receivable_aging_31_60'.tr, aging.days31to60, true),
              _AgingChip('receivable_aging_61_90'.tr, aging.days61to90, true),
              _AgingChip('receivable_aging_over_90'.tr, aging.over90, true),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgingChip extends StatelessWidget {
  const _AgingChip(this.label, this.amount, this.isOverdue);

  final String label;
  final double amount;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final highlight = isOverdue && amount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Text(
            Formatters.money(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: highlight ? AppColors.dangerInk : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends GetView<CustomerStatementController> {
  const _Actions({required this.statement});

  final CustomerStatement statement;

  Future<void> _receive() async {
    final input = await ReceivePaymentDialog.show(statement);
    if (input == null) return;
    final receipt = await controller.receivePayment(
      amount: input.amount,
      method: input.method,
      reference: input.reference,
      billingNoteId: input.billingNoteId,
    );
    if (receipt != null) await _openReceipt(controller, receipt.id);
  }

  Future<void> _issueNote() async {
    final unbilled = statement.unbilledInvoices;
    final total = unbilled.fold<double>(0, (sum, i) => sum + i.outstanding);
    final confirmed = await AppDialogs.confirm(
      title: 'receivable_billing_note_confirm_title'.tr,
      message: 'receivable_billing_note_confirm_message'.trParams({
        'count': '${unbilled.length}',
        'amount': Formatters.baht(total),
      }),
      confirmLabel: 'receivable_issue_billing_note'.tr,
    );
    if (!confirmed) return;
    final note = await controller.issueBillingNote();
    if (note != null) await _openBillingNote(controller, note.id);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isSubmitting.value;
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              key: const ValueKey('statement-receive-payment'),
              onPressed: busy || statement.summary.outstanding <= 0
                  ? null
                  : _receive,
              icon: const Icon(Icons.payments_outlined),
              label: Text('receivable_receive_payment'.tr),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              key: const ValueKey('statement-issue-billing-note'),
              onPressed: busy || statement.unbilledInvoices.isEmpty
                  ? null
                  : _issueNote,
              icon: const Icon(Icons.request_quote_outlined),
              label: Text('receivable_issue_billing_note'.tr),
            ),
          ),
        ],
      );
    });
  }
}

Future<void> _openReceipt(
  CustomerStatementController controller,
  int id,
) async {
  final receipt = await controller.fetchReceipt(id);
  if (receipt == null) return;
  final reason = await ReceivableDocumentDialog.showReceipt(
    receipt,
    canVoid: controller.canVoid,
  );
  if (reason != null) await controller.voidReceipt(id, reason);
}

Future<void> _openBillingNote(
  CustomerStatementController controller,
  int id,
) async {
  final note = await controller.fetchBillingNote(id);
  if (note == null) return;
  final reason = await ReceivableDocumentDialog.showBillingNote(
    note,
    canVoid: controller.canVoid,
  );
  if (reason != null) await controller.voidBillingNote(id, reason);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
    );
  }
}

/// กรอบรายการเดียวกันทั้งสามหมวด ให้หน้าอ่านเป็นตารางเดินบัญชีต่อเนื่อง
class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.chip,
    this.trailingNote,
    this.onTap,
    this.dimmed = false,
    this.tileKey,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Widget? chip;
  final String? trailingNote;
  final VoidCallback? onTap;
  final bool dimmed;
  final Key? tileKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: tileKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              decoration: dimmed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          ?chip,
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dimmed ? AppColors.textDisabled : null,
                      ),
                    ),
                    if (trailingNote != null)
                      Text(
                        trailingNote!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice});

  final CreditInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final Widget chip;
    if (!invoice.isOpen) {
      chip = StatusChip(
        label: 'receivable_invoice_settled'.tr,
        color: AppColors.success,
        dense: true,
      );
    } else if (invoice.isOverdue) {
      chip = StatusChip(
        label: 'receivable_invoice_overdue_days'.trParams({
          'days': '${invoice.daysOverdue}',
        }),
        color: AppColors.danger,
        dense: true,
      );
    } else {
      chip = StatusChip(
        label: 'receivable_invoice_not_due'.tr,
        color: AppColors.info,
        dense: true,
      );
    }
    return _EntryTile(
      tileKey: ValueKey('statement-invoice-${invoice.paymentId}'),
      title: '#${invoice.orderCode}',
      chip: chip,
      subtitle: [
        'receivable_line_dates'.trParams({
          'date': Formatters.dateTime(invoice.createdAt),
          'due': Formatters.dueDate(invoice.dueDate),
        }),
        if (invoice.billingNoteNo != null) invoice.billingNoteNo!,
      ].join(' · '),
      amount: Formatters.baht(invoice.amount),
      trailingNote: invoice.isOpen && invoice.outstanding != invoice.amount
          ? 'receivable_invoice_remaining'.trParams({
              'amount': Formatters.money(invoice.outstanding),
            })
          : null,
      onTap: () => Get.toNamed<void>(
        AppRoutes.orderDetail,
        arguments: {'orderId': invoice.orderId},
      ),
    );
  }
}

class _BillingNoteTile extends GetView<CustomerStatementController> {
  const _BillingNoteTile({required this.note});

  final BillingNote note;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (note.status) {
      BillingNoteStatus.paid => (
        'receivable_note_status_paid'.tr,
        AppColors.success,
      ),
      BillingNoteStatus.voided => (
        'receivable_document_voided'.tr,
        AppColors.danger,
      ),
      _ => ('receivable_note_status_open'.tr, AppColors.warning),
    };
    return _EntryTile(
      tileKey: ValueKey('statement-billing-note-${note.id}'),
      title: note.noteNo,
      chip: StatusChip(label: label, color: color, dense: true),
      subtitle: 'receivable_note_line'.trParams({
        'date': Formatters.dateTime(note.issuedAt),
        'due': Formatters.dueDate(note.dueDate),
      }),
      amount: Formatters.baht(note.total),
      trailingNote: note.isOpen && note.remaining != note.total
          ? 'receivable_invoice_remaining'.trParams({
              'amount': Formatters.money(note.remaining),
            })
          : null,
      dimmed: note.isVoided,
      onTap: () => _openBillingNote(controller, note.id),
    );
  }
}

class _ReceiptTile extends GetView<CustomerStatementController> {
  const _ReceiptTile({required this.receipt});

  final ArReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return _EntryTile(
      tileKey: ValueKey('statement-receipt-${receipt.id}'),
      title: receipt.receiptNo,
      chip: receipt.isVoided
          ? StatusChip(
              label: 'receivable_document_voided'.tr,
              color: AppColors.danger,
              dense: true,
            )
          : null,
      subtitle:
          '${Formatters.dateTime(receipt.receivedAt)} · '
          '${PaymentMethod.label(receipt.method)}',
      amount: Formatters.baht(receipt.amount),
      dimmed: receipt.isVoided,
      onTap: () => _openReceipt(controller, receipt.id),
    );
  }
}
