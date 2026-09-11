import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/promotion.dart';
import '../controllers/promotions_controller.dart';

/// หน้าจัดการโปรโมชัน — สำหรับผู้จัดการ/แอดมิน
class PromotionsPage extends GetView<PromotionsController> {
  const PromotionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-promotions',
        onPressed: () => controller.openForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text('promotion_add_button'.tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();

        final error = controller.errorMessage.value;
        if (error != null && controller.promotions.isEmpty) {
          return ErrorView(message: error, onRetry: controller.load);
        }

        if (controller.promotions.isEmpty) {
          return EmptyView(
            message: 'promotion_empty_state'.tr,
            icon: Icons.local_offer_outlined,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: controller.promotions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _PromotionRow(promotion: controller.promotions[index]),
        );
      }),
    );
  }
}

class _PromotionRow extends GetView<PromotionsController> {
  const _PromotionRow({required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: promotion.isActive
                  ? AppColors.primarySoft
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.local_offer_rounded,
              color: promotion.isActive
                  ? AppColors.primary
                  : AppColors.textDisabled,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        promotion.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (promotion.requiresCode) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          promotion.code!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  promotion.type == 'bogo'
                      ? promotion.typeLabel
                      : '${promotion.typeLabel} · ${Formatters.money(promotion.value)}'
                            '${promotion.type == 'percent' ? '%' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: promotion.isActive,
            onChanged: (_) => controller.toggleActive(promotion),
          ),
          IconButton(
            onPressed: () => controller.openForm(promotion: promotion),
            icon: const Icon(Icons.edit_outlined, size: 19),
            tooltip: 'common_edit'.tr,
          ),
          IconButton(
            onPressed: () => controller.delete(promotion),
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
            color: AppColors.danger,
            tooltip: 'common_delete'.tr,
          ),
        ],
      ),
    );
  }
}
