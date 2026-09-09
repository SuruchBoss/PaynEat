import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../order/domain/entities/order_item.dart';
import '../controllers/kitchen_controller.dart';
import '../widgets/kitchen_ticket_card.dart';

/// จอครัว — แบ่งเป็น 3 คอลัมน์ตามสถานะ เห็นภาพรวมงานทั้งครัวในจอเดียว
class KitchenPage extends GetView<KitchenController> {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _KitchenHeader(),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.queue.isEmpty) {
              return LoadingView(message: 'kitchen_loading_queue'.tr);
            }
            final error = controller.errorMessage.value;
            if (error != null && controller.queue.isEmpty) {
              return ErrorView(message: error, onRetry: controller.load);
            }
            if (controller.queue.isEmpty) {
              return EmptyView(
                message: 'kitchen_empty_queue_message'.tr,
                icon: Icons.restaurant_rounded,
              );
            }

            // อ่านค่า tick เพื่อให้ "เวลารอ" อัปเดตทุก 30 วินาที
            controller.tick.value;

            final columns = [
              (
                title: OrderItemStatus.label(OrderItemStatus.pending),
                status: OrderItemStatus.pending,
                items: controller.pending,
                color: AppColors.warning,
              ),
              (
                title: OrderItemStatus.label(OrderItemStatus.cooking),
                status: OrderItemStatus.cooking,
                items: controller.cooking,
                color: AppColors.primary,
              ),
              (
                title: OrderItemStatus.label(OrderItemStatus.ready),
                status: OrderItemStatus.ready,
                items: controller.ready,
                color: AppColors.success,
              ),
            ];

            if (Responsive.isMobile(context)) {
              return DefaultTabController(
                length: columns.length,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      tabs: columns
                          .map(
                            (column) => Tab(
                              text: 'kitchen_column_count_label'.trParams({
                                'title': column.title,
                                'count': column.items.length.toString(),
                              }),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: columns
                            .map(
                              (column) => _TicketList(
                                items: column.items,
                                emptyMessage: 'kitchen_column_empty'.trParams({
                                  'title': column.title,
                                }),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: columns
                  .map(
                    (column) => Expanded(
                      child: _KitchenColumn(
                        title: column.title,
                        color: column.color,
                        items: column.items,
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          }),
        ),
      ],
    );
  }
}

class _KitchenHeader extends GetView<KitchenController> {
  const _KitchenHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Obx(
        () => Row(
          children: [
            const Icon(Icons.soup_kitchen_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'kitchen_header_title'.tr,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'kitchen_queue_count'.trParams({
                  'count': controller.queue.length.toString(),
                }),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (controller.lateCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'kitchen_late_count'.trParams({
                        'count': controller.lateCount.toString(),
                      }),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            IconButton(
              onPressed: controller.load,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'kitchen_refresh_tooltip'.tr,
            ),
          ],
        ),
      ),
    );
  }
}

class _KitchenColumn extends StatelessWidget {
  const _KitchenColumn({
    required this.title,
    required this.color,
    required this.items,
  });

  final String title;
  final Color color;
  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _TicketList(
            items: items,
            emptyMessage: 'kitchen_column_empty'.trParams({'title': title}),
          ),
        ),
      ],
    );
  }
}

class _TicketList extends GetView<KitchenController> {
  const _TicketList({required this.items, required this.emptyMessage});

  final List<OrderItem> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: AppColors.textDisabled, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return KitchenTicketCard(
          item: item,
          isLate: controller.isLate(item),
          onAdvance: () => controller.advance(item),
        );
      },
    );
  }
}
