import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/ingredient.dart';
import '../controllers/ingredients_controller.dart';
import '../widgets/adjust_stock_dialog.dart';

/// หน้าจัดการวัตถุดิบ/สต๊อก — สำหรับผู้จัดการ/แอดมิน
class IngredientsPage extends GetView<IngredientsController> {
  const IngredientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-ingredients',
        onPressed: () => controller.openForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text('ingredient_add_button'.tr),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Obx(
              () => FilterChip(
                label: Text('ingredient_low_stock_filter'.tr),
                avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                selected: controller.lowStockOnly.value,
                onSelected: controller.toggleLowStockOnly,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const LoadingView();

              final error = controller.errorMessage.value;
              if (error != null && controller.ingredients.isEmpty) {
                return ErrorView(message: error, onRetry: controller.load);
              }

              if (controller.ingredients.isEmpty) {
                return EmptyView(
                  message: 'ingredient_empty_state'.tr,
                  icon: Icons.inventory_2_outlined,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                itemCount: controller.ingredients.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _IngredientRow(ingredient: controller.ingredients[index]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends GetView<IngredientsController> {
  const _IngredientRow({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ingredient.isLowStock ? AppColors.warning : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ingredient.isLowStock
                  ? AppColors.warning.withValues(alpha: 0.12)
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: ingredient.isLowStock
                  ? AppColors.warning
                  : AppColors.textSecondary,
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
                        ingredient.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ingredient.isLowStock) ...[
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
                          'ingredient_low_stock_badge'.tr,
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
                  'ingredient_stock_summary'.trParams({
                    'stock': ingredient.currentStock.toStringAsFixed(1),
                    'unit': ingredient.unit,
                    'threshold': ingredient.lowStockThreshold.toStringAsFixed(
                      1,
                    ),
                  }),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final result = await AdjustStockDialog.show(ingredient);
              if (result != null) {
                controller.adjustStock(ingredient, result.delta);
              }
            },
            icon: const Icon(Icons.tune_rounded, size: 19),
            tooltip: 'ingredient_adjust_stock_tooltip'.tr,
          ),
          IconButton(
            onPressed: () => controller.openForm(ingredient: ingredient),
            icon: const Icon(Icons.edit_outlined, size: 19),
            tooltip: 'common_edit'.tr,
          ),
          IconButton(
            onPressed: () => controller.delete(ingredient),
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
            color: AppColors.danger,
            tooltip: 'common_delete'.tr,
          ),
        ],
      ),
    );
  }
}
