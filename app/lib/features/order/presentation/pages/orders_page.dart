import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/order.dart';
import '../controllers/order_list_controller.dart';

/// รายการออเดอร์ทั้งหมด (ใช้ทั้งฝั่งพนักงานและผู้จัดการ)
class OrdersPage extends GetView<OrderListController> {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            height: 34,
            child: Obx(() {
              // อ่านค่า observable ใน scope ของ Obx โดยตรง
              // ถ้าไปอ่านใน itemBuilder ที่ถูกเรียกทีหลัง GetX จะไม่รู้ว่าต้อง rebuild เมื่อค่าเปลี่ยน
              final activeFilter = controller.statusFilter.value;

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: OrderListController.filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = OrderListController.filters[index];
                  final selected = activeFilter == filter.value;
                  return ChoiceChip(
                    label: Text(filter.label),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => controller.setFilter(filter.value),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceAlt,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  );
                },
              );
            }),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.orders.isEmpty) {
              return const LoadingView();
            }
            final error = controller.errorMessage.value;
            if (error != null && controller.orders.isEmpty) {
              return ErrorView(message: error, onRetry: controller.load);
            }
            if (controller.orders.isEmpty) {
              return const EmptyView(
                message: 'ยังไม่มีออเดอร์ในหมวดนี้',
                icon: Icons.receipt_long_outlined,
              );
            }

            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _OrderTile(
                  order: controller.orders[index],
                  onTap: () => controller.openOrder(controller.orders[index]),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.orderStatus(order.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  order.tableName != null
                      ? Icons.table_restaurant_rounded
                      : Icons.takeout_dining_rounded,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.displayTarget,
                          style: const TextStyle(
                            fontSize: 15,
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
                      '${order.code} · ${order.totalQuantity} รายการ · ${Formatters.time(order.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.baht(order.total),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
