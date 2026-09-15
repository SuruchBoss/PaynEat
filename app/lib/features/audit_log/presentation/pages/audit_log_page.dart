import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/entities/audit_log_action.dart';
import '../controllers/audit_log_controller.dart';

/// หน้าประวัติ audit log — admin เท่านั้น (ดู docs/tickets/08-audit-log.md)
/// อ่านอย่างเดียว ไม่มีทางแก้ไข/ลบจากหน้านี้ (append-only)
class AuditLogPage extends GetView<AuditLogController> {
  const AuditLogPage({super.key});

  static Color actionColor(String action) {
    if (action.startsWith('order_item.')) return AppColors.warning;
    if (action.startsWith('order.')) return AppColors.primary;
    if (action.startsWith('user.')) return AppColors.purple;
    if (action.startsWith('settings.')) return AppColors.info;
    if (action.startsWith('payment.')) return AppColors.success;
    if (action.startsWith('tax_invoice.')) return AppColors.danger;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(
                    label: 'common_all'.tr,
                    selected: controller.actionFilter.value == null,
                    color: AppColors.textSecondary,
                    onTap: () => controller.filterByAction(null),
                  ),
                  ...AuditLogAction.all.map(
                    (action) => _ActionChip(
                      label: controller.actionLabel(action),
                      selected: controller.actionFilter.value == action,
                      color: actionColor(action),
                      onTap: () => controller.filterByAction(action),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const LoadingView();

              final error = controller.errorMessage.value;
              if (error != null && controller.logs.isEmpty) {
                return ErrorView(message: error, onRetry: controller.load);
              }

              final logs = controller.logs;
              if (logs.isEmpty) {
                return EmptyView(
                  message: 'audit_log_empty_state'.tr,
                  icon: Icons.history_rounded,
                );
              }

              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _AuditLogRow(log: logs[index]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.fillOf(color),
      backgroundColor: AppColors.surfaceAlt,
      labelStyle: TextStyle(
        color: selected
            ? AppColors.onColor(AppColors.fillOf(color))
            : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
    );
  }
}

class _AuditLogRow extends StatelessWidget {
  const _AuditLogRow({required this.log});

  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    final color = AuditLogPage.actionColor(log.action);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(
                label: AuditLogAction.translationKey(log.action).tr,
                color: color,
                dense: true,
              ),
              const Spacer(),
              Text(
                Formatters.dateTime(log.createdAt),
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.summary,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (log.reason != null && log.reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'audit_log_reason_prefix'.trParams({'reason': log.reason!}),
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'audit_log_actor_prefix'.trParams({'name': log.actorName}),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
