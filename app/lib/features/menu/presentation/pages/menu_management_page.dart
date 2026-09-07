import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/menu_item.dart';
import '../controllers/menu_management_controller.dart';
import '../widgets/category_filter_bar.dart';

/// หน้าจัดการเมนู — ออกแบบสำหรับจอกว้าง (เว็บผู้ดูแลระบบ) แต่ยังใช้บนแท็บเล็ตได้
class MenuManagementPage extends GetView<MenuManagementController> {
  const MenuManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มเมนู'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: controller.search,
                        decoration: const InputDecoration(
                          hintText: 'ค้นหาเมนู...',
                          prefixIcon: Icon(Icons.search_rounded),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _openCategorySheet(context),
                      icon: const Icon(Icons.category_rounded, size: 17),
                      label: const Text('หมวดหมู่'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Row(
                    children: [
                      Text(
                        'ทั้งหมด ${controller.items.length} เมนู',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      if (controller.unavailableCount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ปิดขายอยู่ ${controller.unavailableCount}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.danger,
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
                return const EmptyView(
                  message: 'ยังไม่มีเมนูในหมวดนี้',
                  icon: Icons.restaurant_menu_rounded,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
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
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        decoration: const BoxDecoration(
          color: Colors.white,
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
              color: item.isAvailable ? AppColors.primarySoft : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              item.name.substring(0, 1),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: item.isAvailable ? AppColors.primary : AppColors.textDisabled,
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
                        item.name,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isRecommended) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, size: 15, color: AppColors.warning),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.categoryName ?? '-'} · ${Formatters.baht(item.price)}'
                  '${item.hasOptions ? ' · ${item.optionGroups.length} กลุ่มตัวเลือก' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
            tooltip: 'แก้ไข',
          ),
          IconButton(
            onPressed: () => controller.delete(item),
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
            color: AppColors.danger,
            tooltip: 'ลบ',
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
              const Text(
                'จัดการหมวดหมู่',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('เพิ่ม'),
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
                  title: Text(category.name),
                  subtitle: Text('${category.itemCount} เมนู'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showCategoryDialog(category: category),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                      IconButton(
                        onPressed: () => controller.deleteCategory(category),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: AppColors.danger,
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
        title: Text(category == null ? 'เพิ่มหมวดหมู่' : 'แก้ไขหมวดหมู่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'ชื่อหมวดหมู่'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: 'ไอคอน (อีโมจิ)',
                hintText: '🍛',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back<void>(), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Get.back(result: true), child: const Text('บันทึก')),
        ],
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      await controller.saveCategory(
        id: category?.id,
        name: nameController.text.trim(),
        icon: iconController.text.trim().isEmpty ? null : iconController.text.trim(),
      );
    }
  }
}
