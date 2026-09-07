import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';
import '../../../menu/presentation/widgets/category_filter_bar.dart';
import '../../../menu/presentation/widgets/menu_item_card.dart';
import '../controllers/cart_controller.dart';
import '../widgets/cart_panel.dart';
import '../widgets/option_selection_sheet.dart';

/// หน้าจอรับออเดอร์ — ด้านซ้ายเลือกเมนู ด้านขวาคือตะกร้า
///
/// บนแท็บเล็ต/เว็บจะแสดงสองคอลัมน์คู่กัน ส่วนบนมือถือตะกร้าจะยุบเป็นแถบล่างที่กดเปิดได้
class OrderTakingPage extends GetView<MenuBrowseController> {
  const OrderTakingPage({super.key});

  CartController get cart => Get.find<CartController>();

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          cart.isAddingToExistingOrder
              ? 'สั่งอาหารเพิ่ม'
              : cart.tableName != null
              ? 'รับออเดอร์ · โต๊ะ ${cart.tableName}'
              : 'ออเดอร์กลับบ้าน',
        ),
        actions: [
          if (!isWide)
            Obx(
              () => cart.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      onPressed: () => _openCartSheet(context),
                      icon: Badge(
                        label: Text('${cart.totalQuantity}'),
                        child: const Icon(Icons.shopping_basket_outlined),
                      ),
                    ),
            ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                const Expanded(child: _MenuSection()),
                Container(
                  width: 380,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(left: BorderSide(color: AppColors.border)),
                  ),
                  child: const CartPanel(),
                ),
              ],
            )
          : const _MenuSection(),
      bottomNavigationBar: isWide
          ? null
          : _MobileCartBar(onTap: () => _openCartSheet(context)),
    );
  }

  void _openCartSheet(BuildContext context) {
    Get.bottomSheet<void>(
      Container(
        height: MediaQuery.sizeOf(context).height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        clipBehavior: Clip.antiAlias,
        child: const CartPanel(),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _MenuSection extends GetView<MenuBrowseController> {
  const _MenuSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: TextField(
            onChanged: controller.search,
            decoration: const InputDecoration(
              hintText: 'ค้นหาเมนู...',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
        ),
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
            if (controller.isLoading.value) {
              return const LoadingView(message: 'กำลังโหลดเมนู...');
            }
            final error = controller.errorMessage.value;
            if (error != null && controller.items.isEmpty) {
              return ErrorView(message: error, onRetry: controller.load);
            }

            final items = controller.filteredItems;
            if (items.isEmpty) {
              return const EmptyView(
                message: 'ไม่พบเมนูที่ค้นหา',
                icon: Icons.search_off_rounded,
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = Responsive.gridColumns(
                  constraints.maxWidth - 32,
                  minTileWidth: 165,
                );
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.86,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return MenuItemCard(
                      item: item,
                      showAvailabilityBadge: true,
                      onTap: () => _addToCart(item),
                    );
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }

  /// มีตัวเลือกให้เลือก → เปิดแผ่นเลือกก่อน, ไม่มี → ใส่ตะกร้าเลย 1 ที่
  Future<void> _addToCart(MenuItem item) async {
    final cart = Get.find<CartController>();

    if (!item.requiresSelection) {
      cart.addItem(item);
      return;
    }

    final result = await OptionSelectionSheet.show(item);
    if (result == null) return;

    cart.addItem(
      item,
      quantity: result.quantity,
      options: result.options,
      note: result.note,
    );
  }
}

/// แถบตะกร้าด้านล่างสำหรับมือถือ
class _MobileCartBar extends StatelessWidget {
  const _MobileCartBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();

    return Obx(() {
      if (cart.isEmpty) return const SizedBox.shrink();

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${cart.totalQuantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ดูตะกร้า',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.baht(cart.preview.total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
