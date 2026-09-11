import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../table/domain/usecases/table_usecases.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/order_usecases.dart';
import '../controllers/order_detail_controller.dart';
import '../widgets/bill_summary.dart';
import '../widgets/discount_dialog.dart';
import '../widgets/order_item_tile.dart';
import '../widgets/order_picker_dialog.dart';
import '../widgets/promotion_code_dialog.dart';
import '../widgets/table_picker_dialog.dart';

/// หน้ารายละเอียดออเดอร์ — ดูรายการ เดินสถานะ ให้ส่วนลด และไปหน้าชำระเงิน
class OrderDetailPage extends GetView<OrderDetailController> {
  const OrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(controller.order.value?.code ?? 'order_detail_title'.tr),
        ),
        actions: [
          Obx(() {
            final order = controller.order.value;
            if (order == null) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) => _handleMenu(value, order),
              itemBuilder: (context) => [
                if (order.isActive)
                  PopupMenuItem(
                    value: 'discount',
                    child: ListTile(
                      leading: const Icon(Icons.percent_rounded),
                      title: Text('order_menu_discount'.tr),
                      dense: true,
                    ),
                  ),
                if (order.isActive)
                  PopupMenuItem(
                    value: 'promotion',
                    child: ListTile(
                      leading: const Icon(Icons.local_offer_outlined),
                      title: Text('promotion_dialog_title'.tr),
                      dense: true,
                    ),
                  ),
                if (order.isPaid)
                  PopupMenuItem(
                    value: 'receipt',
                    child: ListTile(
                      leading: const Icon(Icons.receipt_rounded),
                      title: Text('order_menu_view_receipt'.tr),
                      dense: true,
                    ),
                  ),
                if (order.isActive && order.tableId != null)
                  PopupMenuItem(
                    value: 'moveTable',
                    child: ListTile(
                      leading: const Icon(Icons.swap_horiz_rounded),
                      title: Text('order_menu_move_table'.tr),
                      dense: true,
                    ),
                  ),
                if (order.isActive)
                  PopupMenuItem(
                    value: 'merge',
                    child: ListTile(
                      leading: const Icon(Icons.call_merge_rounded),
                      title: Text('order_menu_merge_bill'.tr),
                      dense: true,
                    ),
                  ),
                if (order.isActive && controller.canCollectPayment)
                  PopupMenuItem(
                    value: 'splitBill',
                    child: ListTile(
                      leading: const Icon(Icons.call_split_rounded),
                      title: Text('order_menu_split_bill'.tr),
                      dense: true,
                    ),
                  ),
                if (order.isActive && controller.canManage)
                  PopupMenuItem(
                    value: 'cancel',
                    child: ListTile(
                      leading: Icon(
                        Icons.cancel_outlined,
                        color: AppColors.danger,
                      ),
                      title: Text(
                        'order_menu_cancel_order'.tr,
                        style: const TextStyle(color: AppColors.dangerInk),
                      ),
                      dense: true,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return LoadingView(message: 'order_detail_loading'.tr);
        }
        final error = controller.errorMessage.value;
        if (error != null) {
          return ErrorView(message: error, onRetry: controller.load);
        }
        final order = controller.order.value;
        if (order == null) {
          return EmptyView(message: 'order_not_found'.tr);
        }

        final isWide = Responsive.isWide(context);
        final itemList = _ItemList(order: order);
        final billCard = _BillCard(order: order);

        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: itemList),
                  SizedBox(
                    width: 360,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                      child: billCard,
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _OrderHeader(order: order),
                  _ItemList(order: order, shrinkWrap: true),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: billCard,
                  ),
                ],
              );
      }),
    );
  }

  Future<void> _handleMenu(String value, Order order) async {
    switch (value) {
      case 'discount':
        final result = await DiscountDialog.show(
          currentType: order.discountType,
        );
        if (result != null) {
          await controller.applyDiscount(
            type: result.type,
            value: result.value,
          );
        }
      case 'promotion':
        await _openPromotionDialog(order);
      case 'receipt':
        await controller.openReceipt();
      case 'moveTable':
        await _moveTable(order);
      case 'merge':
        await _mergeBill(order);
      case 'splitBill':
        await Get.toNamed<void>(
          AppRoutes.splitBill,
          arguments: {'orderId': order.id},
        );
      case 'cancel':
        await _confirmCancel();
    }
  }

  Future<void> _moveTable(Order order) async {
    final result = await Get.find<GetTablesUseCase>()(
      const TableFilter(status: TableStatus.available),
    );
    final tables = result.dataOrNull ?? const [];
    final tableId = await TablePickerDialog.show(tables);
    if (tableId != null) {
      await controller.moveTable(tableId);
    }
  }

  Future<void> _mergeBill(Order order) async {
    final result = await Get.find<GetOrdersUseCase>()(
      const OrderListFilter(activeOnly: true, limit: 100),
    );
    final orders = (result.dataOrNull?.orders ?? const [])
        .where((row) => row.id != order.id)
        .toList(growable: false);
    final sourceOrderId = await OrderPickerDialog.show(orders);
    if (sourceOrderId != null) {
      await controller.mergeInto(sourceOrderId);
    }
  }

  Future<void> _openPromotionDialog(Order order) async {
    final eligible = await controller.loadEligiblePromotions();
    final result = await PromotionCodeDialog.show(
      eligible: eligible,
      currentPromotionCode: order.promotionCode,
    );
    if (result == null) return;
    if (result.isRemove) {
      await controller.removePromotion();
    } else if (result.code != null) {
      await controller.redeemPromotionCode(result.code!);
    }
  }

  Future<void> _confirmCancel() async {
    final reasonController = TextEditingController();
    final reason = await Get.dialog<String>(
      AlertDialog(
        title: Text('order_menu_cancel_order'.tr),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'order_cancel_order_reason_label'.tr,
            hintText: 'order_cancel_order_reason_hint'.tr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: Text('common_close'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Get.back(result: reasonController.text.trim()),
            child: Text('order_cancel_order_confirm_button'.tr),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      await controller.cancelOrder(reason);
    }
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                order.displayTarget,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              StatusChip(
                label: order.statusLabel,
                color: AppColors.orderStatus(order.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _MetaText(icon: Icons.tag_rounded, text: order.code),
              _MetaText(
                icon: Icons.people_outline_rounded,
                text: 'order_guest_count_summary'.trParams({
                  'count': '${order.guestCount}',
                }),
              ),
              if (order.waiterName != null)
                _MetaText(
                  icon: Icons.person_outline_rounded,
                  text: order.waiterName!,
                ),
              _MetaText(
                icon: Icons.schedule_rounded,
                text:
                    '${Formatters.time(order.createdAt)} (${Formatters.elapsed(order.createdAt)})',
              ),
            ],
          ),
          if (order.isCancelled && order.cancelledReason != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'order_cancelled_reason_prefix'.trParams({
                  'reason': order.cancelledReason!,
                }),
                style: const TextStyle(
                  color: AppColors.dangerInk,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textDisabled),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ItemList extends GetView<OrderDetailController> {
  const _ItemList({required this.order, this.shrinkWrap = false});

  final Order order;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final content = ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(16),
      itemCount: order.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = order.items[index];
        return OrderItemTile(
          item: item,
          showActions: order.isActive,
          onAdvance: () => controller.advanceItemStatus(item),
          onRemove: () => controller.removeItem(item),
          onCancel: controller.canManage
              ? () => controller.cancelItem(item)
              : null,
        );
      },
    );

    if (shrinkWrap) return content;

    return Column(
      children: [
        _OrderHeader(order: order),
        Expanded(child: content),
      ],
    );
  }
}

class _BillCard extends GetView<OrderDetailController> {
  const _BillCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BillSummary(order: order),
          if (order.isActive) ...[
            const SizedBox(height: 16),
            if (order.canSendToKitchen)
              FilledButton.icon(
                onPressed: controller.isBusy.value
                    ? null
                    : controller.sendToKitchen,
                icon: const Icon(Icons.soup_kitchen_rounded, size: 18),
                label: Text('order_send_to_kitchen_button'.tr),
              ),
            if (order.canSendToKitchen) const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: controller.addMoreItems,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('order_add_more_items_button'.tr),
            ),
            const SizedBox(height: 8),
            if (controller.canCollectPayment)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                onPressed: controller.goToCheckout,
                icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                label: Text('order_checkout_button'.tr),
              ),
          ],
          if (order.isPaid) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'order_paid_at_summary'.trParams({
                        'datetime': Formatters.dateTime(order.closedAt),
                      }),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.successInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: controller.openReceipt,
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text('order_menu_view_receipt'.tr),
            ),
          ],
        ],
      ),
    );
  }
}
