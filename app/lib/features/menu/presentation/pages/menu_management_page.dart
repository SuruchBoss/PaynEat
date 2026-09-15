import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/menu_item.dart';
import '../controllers/menu_management_controller.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/menu_item_thumbnail.dart';

/// หน้าจัดการเมนู — ออกแบบสำหรับจอกว้าง (เว็บผู้ดูแลระบบ) แต่ยังใช้บนแท็บเล็ตได้
class MenuManagementPage extends GetView<MenuManagementController> {
  const MenuManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        // ต้องระบุ heroTag เพราะหน้านี้ถูกสร้างพร้อมกับหน้าอื่นใน IndexedStack ของหน้าหลัก
        // ถ้าใช้ค่า default ทั้งคู่ Flutter จะโยน assertion เรื่อง hero tag ซ้ำ
        heroTag: 'fab-menu-management',
        onPressed: () => controller.openForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text('menu_add_item_button'.tr),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: controller.search,
                        decoration: InputDecoration(
                          hintText: 'menu_search_hint'.tr,
                          prefixIcon: const Icon(Icons.search_rounded),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _openCategorySheet(context),
                      icon: const Icon(Icons.category_rounded, size: 17),
                      label: Text('menu_category_button'.tr),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Row(
                    children: [
                      Text(
                        'menu_total_count'.trParams({
                          'count': '${controller.items.length}',
                        }),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (controller.unavailableCount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'menu_unavailable_count'.trParams({
                              'count': '${controller.unavailableCount}',
                            }),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.dangerInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => CategoryFilterBar(
              categories: controller.categories,
              selectedId: controller.selectedCategoryId.value,
              onSelected: controller.selectCategory,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const LoadingView();

              final error = controller.errorMessage.value;
              if (error != null && controller.items.isEmpty) {
                return ErrorView(message: error, onRetry: controller.load);
              }

              final items = controller.filteredItems;
              if (items.isEmpty) {
                return EmptyView(
                  message: 'menu_empty_category'.tr,
                  icon: Icons.restaurant_menu_rounded,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _MenuRow(item: items[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openCategorySheet(BuildContext context) {
    Get.bottomSheet<void>(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const _CategorySheet(),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _MenuRow extends GetView<MenuManagementController> {
  const _MenuRow({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 44,
              height: 44,
              child: MenuItemThumbnail(
                imageUrl: item.imageUrl,
                placeholder: Container(
                  alignment: Alignment.center,
                  color: item.isAvailable
                      ? AppColors.primarySoft
                      : AppColors.surfaceAlt,
                  child: Text(
                    item.displayName.substring(0, 1),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: item.isAvailable
                          ? AppColors.brandInk
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
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
                        item.displayName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isRecommended) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.warningInk,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.categoryName ?? '-'} · ${Formatters.baht(item.price)}'
                  '${item.hasOptions ? ' · ${'menu_option_groups_count'.trParams({'count': '${item.optionGroups.length}'})}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: item.isAvailable,
            onChanged: (_) => controller.toggleAvailability(item),
          ),
          IconButton(
            onPressed: () => controller.openForm(item: item),
            icon: const Icon(Icons.edit_outlined, size: 19),
            tooltip: 'common_edit'.tr,
          ),
          IconButton(
            onPressed: () => controller.delete(item),
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
            color: AppColors.dangerInk,
            tooltip: 'common_delete'.tr,
          ),
        ],
      ),
    );
  }
}

class _CategorySheet extends GetView<MenuManagementController> {
  const _CategorySheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Text(
                'menu_manage_categories_title'.tr,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('common_add'.tr),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: Obx(
            () => ListView.builder(
              shrinkWrap: true,
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                return ListTile(
                  leading: Text(
                    category.icon ?? '🍽️',
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(category.displayName),
                  subtitle: Text(
                    'menu_category_item_count'.trParams({
                      'count': '${category.itemCount}',
                    }),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            _showCategoryDialog(category: category),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                      IconButton(
                        onPressed: () => controller.deleteCategory(category),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        color: AppColors.dangerInk,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final iconController = TextEditingController(text: category?.icon ?? '');

    final saved = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          category == null
              ? 'menu_add_category_title'.tr
              : 'menu_edit_category_title'.tr,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'menu_category_name_label'.tr,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              maxLength: 2,
              decoration: InputDecoration(
                labelText: 'menu_category_icon_label'.tr,
                hintText: '🍛',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: Text('common_cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('common_save'.tr),
          ),
        ],
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      await controller.saveCategory(
        id: category?.id,
        name: nameController.text.trim(),
        icon: iconController.text.trim().isEmpty
            ? null
            : iconController.text.trim(),
      );
    }
  }
}
