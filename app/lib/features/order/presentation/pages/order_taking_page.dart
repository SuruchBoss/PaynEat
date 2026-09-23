import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';
import '../../../menu/presentation/widgets/category_filter_bar.dart';
import '../../../menu/presentation/widgets/menu_item_card.dart';
import '../../domain/services/barcode_resolver.dart';
import '../controllers/cart_controller.dart';
import '../widgets/cart_panel.dart';
import '../widgets/option_selection_sheet.dart';
import '../widgets/weight_entry_dialog.dart';

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
              ? 'order_taking_title_add'.tr
              : cart.tableName != null
              ? 'order_taking_title_table'.trParams({'table': cart.tableName!})
              : 'order_taking_title_takeaway'.tr,
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
                  decoration: BoxDecoration(
                    color: AppColors.surface,
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
          color: AppColors.surface,
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
          // ช่องสแกนโผล่เฉพาะร้านที่มีสินค้าติดบาร์โค้ด/รหัสตาชั่งจริง — ร้านอาหารทั่วไปที่ไม่มีเครื่องสแกน
          // ไม่ควรเสียช่องค้นหาไปครึ่งหนึ่ง บนมือถือช่องค้นหากว้างกว่า (3:2) และคำใบ้ช่องสแกนสั้นลง
          // เดิมแบ่งครึ่ง คำใบ้ทั้งสองช่องถูกตัดเป็น "Search men..." / "Scan barcod..." ทุกภาษา
          child: Obx(() {
            final canScan = controller.items.any(
              (item) => item.barcode != null || item.scalePlu != null,
            );
            final compact = !Responsive.isWide(context);
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: controller.search,
                    decoration: InputDecoration(
                      hintText: 'order_search_menu_hint'.tr,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                if (canScan) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    flex: compact ? 2 : 3,
                    child: _ScanField(onScanned: _handleScan, compact: compact),
                  ),
                ],
              ],
            );
          }),
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
              return LoadingView(message: 'order_menu_loading'.tr);
            }
            final error = controller.errorMessage.value;
            if (error != null && controller.items.isEmpty) {
              return ErrorView(message: error, onRetry: controller.load);
            }

            final items = controller.filteredItems;
            if (items.isEmpty) {
              return EmptyView(
                message: 'order_menu_search_empty'.tr,
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
  ///
  /// สินค้าขายตามน้ำหนักต้องได้น้ำหนักก่อนเสมอ — จากฉลากตาชั่งที่สแกน ([scannedGrams]) หรือให้
  /// พนักงานกรอกตามหน้าจอตาชั่ง (ดู docs/tickets/18-sell-by-weight.md)
  Future<void> _addToCart(MenuItem item, {int? scannedGrams}) async {
    final cart = Get.find<CartController>();

    var result = const OptionSelectionResult(quantity: 1, options: []);
    if (item.requiresSelection) {
      final picked = await OptionSelectionSheet.show(item);
      if (picked == null) return;
      result = picked;
    }

    if (!item.soldByWeight) {
      cart.addItem(
        item,
        quantity: result.quantity,
        options: result.options,
        note: result.note,
      );
      return;
    }

    final grams =
        scannedGrams ??
        await WeightEntryDialog.show(item, options: result.options);
    if (grams == null) return;
    cart.addWeighedItem(
      item,
      grams,
      options: result.options,
      note: result.note,
    );
  }

  /// รหัสจากเครื่องสแกน (ดู docs/tickets/19-barcode-scale.md) — กรณีที่ใส่ตะกร้าได้เลย
  /// [CartController.applyScan] จัดการให้แล้ว ที่เหลือ (ต้องเลือกตัวเลือก/ต้องชั่ง/อ่านไม่ออก) ทำต่อที่นี่
  Future<void> _handleScan(String code) async {
    final result = Get.find<CartController>().applyScan(code, controller.items);
    switch (result) {
      case ScannedUnitItem(:final item):
        if (item.requiresSelection) {
          await _addToCart(item);
        } else {
          AppDialogs.success(
            'order_scan_added'.trParams({'name': item.displayName}),
          );
        }
      case ScannedWeighedItem(:final item, :final weightGrams):
        if (item.requiresSelection) {
          await _addToCart(item, scannedGrams: weightGrams);
        } else {
          AppDialogs.success(
            'order_scan_added_weight'.trParams({
              'name': item.displayName,
              'weight': Formatters.weight(weightGrams),
            }),
          );
        }
      case ScannedNeedsWeighing(:final item):
        await _addToCart(item);
      case ScanBadCheckDigit():
        AppDialogs.error('order_scan_bad_label'.tr);
      case ScanNotFound(:final code):
        AppDialogs.error('order_scan_not_found'.trParams({'code': code}));
    }
  }
}

/// ช่องรับรหัสจากเครื่องสแกนบาร์โค้ด — เครื่องสแกน USB/บลูทูธทำตัวเป็นคีย์บอร์ด พิมพ์รหัสแล้วกด
/// Enter เอง จึงใช้ TextField ธรรมดาได้ (ไม่ต้องมีไดรเวอร์) เคลียร์และโฟกัสคืนทุกครั้งหลังสแกน
/// ให้สแกนชิ้นต่อไปได้ทันทีโดยไม่ต้องแตะจอ — จอกว้าง (เคาน์เตอร์) โฟกัสช่องนี้ตั้งแต่เปิดหน้า
/// ส่วนมือถือไม่ออโต้โฟกัส ไม่งั้นคีย์บอร์ดเด้งบังเมนูทุกครั้งที่เข้าหน้า
class _ScanField extends StatefulWidget {
  const _ScanField({required this.onScanned, this.compact = false});

  final Future<void> Function(String code) onScanned;

  /// จอแคบ — คำใบ้สั้น ("สแกน") ไอคอนเครื่องสแกนบอกความหมายที่เหลือเอง
  final bool compact;

  @override
  State<_ScanField> createState() => _ScanFieldState();
}

class _ScanFieldState extends State<_ScanField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    _controller.clear();
    if (value.trim().isEmpty) return;
    await widget.onScanned(value);
    if (mounted) _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('order-scan-field'),
      controller: _controller,
      focusNode: _focusNode,
      autofocus: Responsive.isWide(context),
      textInputAction: TextInputAction.done,
      onSubmitted: _submit,
      decoration: InputDecoration(
        hintText:
            (widget.compact ? 'order_scan_hint_short' : 'order_scan_hint').tr,
        prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
        isDense: true,
      ),
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
                    Text(
                      'order_view_cart'.tr,
                      style: const TextStyle(
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
