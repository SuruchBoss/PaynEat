import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/receivable.dart';
import '../controllers/receivables_controller.dart';

/// ลูกหนี้การค้า — ลูกค้าเครดิตทุกรายพร้อมยอดค้าง/เกินกำหนด เรียงรายที่ค้างนานสุดขึ้นก่อน
/// กดเข้าไปรับชำระ/ออกใบวางบิลได้ (admin/manager/cashier — ดู docs/tickets/20-b2b-credit.md)
class ReceivablesPage extends GetView<ReceivablesController> {
  const ReceivablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.summaries.isEmpty) {
        return const LoadingView();
      }
      final error = controller.errorMessage.value;
      if (error != null && controller.summaries.isEmpty) {
        return ErrorView(message: error, onRetry: controller.load);
      }
      if (controller.summaries.isEmpty) {
        return EmptyView(
          message: 'receivable_list_empty'.tr,
          icon: Icons.request_quote_outlined,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TotalsCard(
              outstanding: controller.totalOutstanding,
              overdue: controller.totalOverdue,
              customers: controller.summaries.length,
            ),
            const SizedBox(height: 14),
            for (final summary in controller.summaries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReceivableTile(
                  summary: summary,
                  onTap: () async {
                    await Get.toNamed<void>(
                      AppRoutes.customerStatement,
                      arguments: {'customerId': summary.customer.id},
                    );
                    await controller.load();
                  },
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.outstanding,
    required this.overdue,
    required this.customers,
  });

  final double outstanding;
  final double overdue;
  final int customers;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _Figure(
              label: 'receivable_total_outstanding'.tr,
              value: Formatters.baht(outstanding),
              color: AppColors.brandInk,
            ),
          ),
          Expanded(
            child: _Figure(
              label: 'receivable_total_overdue'.tr,
              value: Formatters.baht(overdue),
              color: overdue > 0 ? AppColors.dangerInk : AppColors.successInk,
            ),
          ),
          Expanded(
            child: _Figure(
              label: 'receivable_total_customers'.tr,
              value: '$customers',
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceivableTile extends StatelessWidget {
  const _ReceivableTile({required this.summary, required this.onTap});

  final ReceivableSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secondary = TextStyle(fontSize: 12.5, color: AppColors.textSecondary);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('receivable-customer-${summary.customer.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: summary.hasOverdue ? AppColors.danger : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wrap ไม่ใช่ Row — ชื่อบริษัทยาว + ชิปยอดเกินกำหนดไม่พอบรรทัดเดียวบนมือถือ 360px
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          summary.customer.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (summary.hasOverdue)
                          StatusChip(
                            label: 'receivable_overdue_chip'.trParams({
                              'amount': Formatters.baht(summary.overdue),
                            }),
                            color: AppColors.danger,
                            dense: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'receivable_limit_line'.trParams({
                        'limit': Formatters.baht(summary.creditLimit),
                        'days': '${summary.creditTermDays}',
                        'available': Formatters.baht(summary.available),
                      }),
                      style: secondary,
                    ),
                    if (summary.openInvoiceCount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'receivable_open_invoices_line'.trParams({
                          'count': '${summary.openInvoiceCount}',
                          'due': Formatters.dueDate(summary.oldestDueDate),
                        }),
                        style: secondary,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.baht(summary.outstanding),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
