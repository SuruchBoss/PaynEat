// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../order/domain/entities/order.dart';
import '../../domain/entities/customer.dart';
import '../controllers/customer_detail_controller.dart';
import '../widgets/customer_credit_dialog.dart';

/// ประวัติการซื้อ/แต้มสะสมของลูกค้ารายคน (admin/manager)
class CustomerDetailPage extends GetView<CustomerDetailController> {
  const CustomerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('customer_detail_title'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();

        final error = controller.errorMessage.value;
        final customer = controller.customer.value;
        if (error != null && customer == null) {
          return ErrorView(message: error, onRetry: controller.load);
        }
        if (customer == null) {
          return EmptyView(message: 'customer_detail_not_found'.tr);
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.phone,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (customer.email != null &&
                        customer.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        customer.email!,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.card_giftcard_rounded,
                            size: 18,
                            color: AppColors.brandInk,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'customer_detail_points_label'.tr,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${customer.pointsBalance}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CreditCard(customer: customer),
              const SizedBox(height: 16),
              Text(
                'customer_detail_history_title'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (controller.orders.isEmpty)
                EmptyView(
                  message: 'customer_detail_history_empty'.tr,
                  icon: Icons.receipt_long_outlined,
                )
              else
                ...controller.orders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OrderHistoryTile(order: order),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

/// บัญชีเครดิต/ขายเชื่อของลูกค้า (ดู docs/tickets/20-b2b-credit.md)
class _CreditCard extends GetView<CustomerDetailController> {
  const _CreditCard({required this.customer});

  final Customer customer;

  Future<void> _edit() async {
    final terms = await CustomerCreditDialog.show(customer);
    if (terms != null) await controller.saveCredit(terms);
  }

  @override
  Widget build(BuildContext context) {
    final secondary = TextStyle(fontSize: 12.5, color: AppColors.textSecondary);
    final outstanding = customer.creditOutstanding ?? 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.request_quote_outlined,
                size: 18,
                color: AppColors.brandInk,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'customer_credit_title'.tr,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (controller.canEditCredit)
                TextButton(
                  key: const ValueKey('customer-credit-edit'),
                  onPressed: _edit,
                  child: Text(
                    customer.hasCreditAccount
                        ? 'customer_credit_edit_button'.tr
                        : 'customer_credit_open_button'.tr,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (!customer.hasCreditAccount && outstanding <= 0)
            Text('customer_credit_none'.tr, style: secondary)
          else ...[
            Text(
              'receivable_limit_term_value'.trParams({
                'limit': Formatters.baht(customer.creditLimit),
                'days': '${customer.creditTermDays}',
              }),
              style: secondary,
            ),
            const SizedBox(height: 4),
            Text(
              'customer_credit_outstanding_available'.trParams({
                'outstanding': Formatters.baht(outstanding),
                'available': Formatters.baht(customer.creditAvailable ?? 0),
              }),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (customer.taxId != null && customer.taxId!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'tax_invoice_tax_id_value'.trParams({'taxId': customer.taxId!}),
                style: secondary,
              ),
            ],
            if (customer.address != null && customer.address!.isNotEmpty)
              Text(customer.address!, style: secondary),
            if (controller.canOpenStatement) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('customer-open-statement'),
                onPressed: () async {
                  await Get.toNamed<void>(
                    AppRoutes.customerStatement,
                    arguments: {'customerId': customer.id},
                  );
                  await controller.load();
                },
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: Text('customer_credit_statement_button'.tr),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _OrderHistoryTile extends StatelessWidget {
  const _OrderHistoryTile({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.orderStatus(order.status);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Get.toNamed<void>(
          AppRoutes.orderDetail,
          arguments: {'orderId': order.id},
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wrap ไม่ใช่ Row — เลขออเดอร์ + ป้ายสถานะภาษาไทยยาวกว่าช่องบนมือถือ 390px
                    // (ล้น 2.5px ตอนลูกค้าเครดิตมีบิลกลับบ้าน) ให้ป้ายขึ้นบรรทัดใหม่แทนการล้น
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          order.code,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        StatusChip(
                          label: order.statusLabel,
                          color: color,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Formatters.dateTime(order.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (order.pointsEarned > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        'customer_detail_points_earned'.trParams({
                          'points': '${order.pointsEarned}',
                        }),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.successInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                Formatters.baht(order.total),
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
