import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../order/domain/entities/order.dart';
import '../controllers/customer_detail_controller.dart';

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
                    Row(
                      children: [
                        Text(
                          order.code,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
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
