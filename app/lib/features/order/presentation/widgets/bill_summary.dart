import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/order.dart';

/// สรุปยอดบิลของออเดอร์ (ใช้ทั้งหน้ารายละเอียด หน้าชำระเงิน และใบเสร็จ)
class BillSummary extends StatelessWidget {
  const BillSummary({super.key, required this.order, this.dense = false});

  final Order order;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(
          'order_subtotal_with_count'.trParams({
            'count': '${order.totalQuantity}',
          }),
          order.subtotal,
        ),
        if (order.hasDiscount)
          _row(
            order.discountType == 'percent'
                ? 'order_discount_percent_label'.trParams({
                    'percent': order.discountValue.toStringAsFixed(0),
                  })
                : 'order_discount_label'.tr,
            -order.discountAmount,
            color: AppColors.success,
          ),
        if (order.hasPromotion)
          _row(
            'promotion_summary_label'.trParams({
              'name': order.promotionName ?? '',
            }),
            -order.promotionDiscountAmount,
            color: AppColors.success,
          ),
        _row('order_service_charge_label'.tr, order.serviceCharge),
        _row('order_vat_label'.tr, order.vat),
        Padding(
          padding: EdgeInsets.symmetric(vertical: dense ? 6 : 10),
          child: const Divider(height: 1),
        ),
        Row(
          children: [
            Text(
              'order_total_label'.tr,
              style: TextStyle(
                fontSize: dense ? 15 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              Formatters.baht(order.total),
              style: TextStyle(
                fontSize: dense ? 20 : 24,
                fontWeight: FontWeight.w900,
                color: AppColors.brandInk,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, double value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: color ?? AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          '${value < 0 ? '-' : ''}${Formatters.money(value.abs())}',
          style: TextStyle(
            fontSize: 13.5,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
