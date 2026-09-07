import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../../../core/widgets/state_views.dart';
import '../controllers/cart_controller.dart';

/// แผงตะกร้า — ใช้ทั้งเป็นคอลัมน์ขวาบนแท็บเล็ต/เว็บ และเป็น bottom sheet บนมือถือ
class CartPanel extends GetView<CartController> {
  const CartPanel({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showHeader) const _CartHeader(),
        const Divider(height: 1),
        Expanded(
          child: Obx(() {
            if (controller.isEmpty) {
              return const EmptyView(
                message: 'ยังไม่มีรายการในออเดอร์\nแตะเมนูทางซ้ายเพื่อเพิ่ม',
                icon: Icons.shopping_basket_outlined,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: controller.lines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _CartLineTile(index: index),
            );
          }),
        ),
        const _CartFooter(),
      ],
    );
  }
}

class _CartHeader extends GetView<CartController> {
  const _CartHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.isAddingToExistingOrder
                      ? 'สั่งเพิ่ม'
                      : controller.tableName != null
                          ? 'โต๊ะ ${controller.tableName}'
                          : 'ออเดอร์ใหม่',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Obx(
                () => controller.isEmpty
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: controller.clear,
                        child: const Text('ล้าง'),
                      ),
              ),
            ],
          ),
          if (!controller.isAddingToExistingOrder) ...[
            const SizedBox(height: 8),
            Obx(
              () => Row(
                children: [
                  if (controller.tableId == null) ...[
                    _TypeToggle(
                      label: 'กลับบ้าน',
                      selected: controller.orderType.value == OrderType.takeaway,
                      onTap: () => controller.setOrderType(OrderType.takeaway),
                    ),
                    const SizedBox(width: 8),
                    _TypeToggle(
                      label: 'เดลิเวอรี',
                      selected: controller.orderType.value == OrderType.delivery,
                      onTap: () => controller.setOrderType(OrderType.delivery),
                    ),
                  ] else ...[
                    const Icon(Icons.people_outline_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    const Text('จำนวนลูกค้า', style: TextStyle(fontSize: 13)),
                    const Spacer(),
                    QuantityStepper(
                      value: controller.guestCount.value,
                      min: 1,
                      max: 50,
                      size: 30,
                      onChanged: controller.setGuestCount,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: EdgeInsets.zero,
          backgroundColor: selected ? AppColors.primarySoft : null,
          side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
          foregroundColor: selected ? AppColors.primary : AppColors.textSecondary,
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

class _CartLineTile extends GetView<CartController> {
  const _CartLineTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final line = controller.lines[index];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.menuItem.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    if (line.selectedOptions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          line.optionsSummary,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    if (line.note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note_rounded,
                                size: 13, color: AppColors.warning),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                line.note!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.warning,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => controller.removeAt(index),
                icon: const Icon(Icons.close_rounded, size: 16),
                visualDensity: VisualDensity.compact,
                color: AppColors.textDisabled,
                tooltip: 'ลบรายการ',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              QuantityStepper(
                value: line.quantity,
                size: 30,
                min: 1,
                onChanged: (value) => controller.updateQuantity(index, value),
              ),
              const Spacer(),
              Text(
                Formatters.baht(line.lineTotal),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartFooter extends GetView<CartController> {
  const _CartFooter();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preview = controller.preview;
      final settings = controller.settings.value;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          children: [
            _SummaryRow(label: 'ยอดรวมอาหาร', value: preview.subtotal),
            _SummaryRow(
              label: 'Service Charge ${settings.serviceChargePercent.toStringAsFixed(0)}%',
              value: preview.serviceCharge,
            ),
            _SummaryRow(
              label: 'VAT ${settings.vatPercent.toStringAsFixed(0)}%',
              value: preview.vat,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Text(
                  'รวมทั้งสิ้น',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  Formatters.baht(preview.total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.isEmpty || controller.isSubmitting.value
                    ? null
                    : () => controller.submit(),
                icon: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.soup_kitchen_rounded, size: 18),
                label: Text(
                  controller.isAddingToExistingOrder
                      ? 'ยืนยันสั่งเพิ่ม (${controller.totalQuantity})'
                      : 'ยืนยันและส่งครัว (${controller.totalQuantity})',
                ),
              ),
            ),
            if (!controller.isAddingToExistingOrder) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: controller.isEmpty || controller.isSubmitting.value
                      ? null
                      : () => controller.submit(sendToKitchenNow: false),
                  child: const Text('บันทึกไว้ก่อน (ยังไม่ส่งครัว)'),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(Formatters.money(value), style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
