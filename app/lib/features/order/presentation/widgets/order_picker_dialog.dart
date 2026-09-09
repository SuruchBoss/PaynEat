import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/order.dart';

/// กล่องเลือกออเดอร์ต้นทางที่จะรวมเข้ากับบิลนี้
class OrderPickerDialog extends StatelessWidget {
  const OrderPickerDialog({super.key, required this.orders});

  final List<Order> orders;

  static Future<int?> show(List<Order> orders) =>
      Get.dialog<int>(OrderPickerDialog(orders: orders));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('order_merge_picker_title'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: orders.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('order_merge_picker_empty'.tr),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    leading: const Icon(Icons.receipt_long_rounded),
                    title: Text(order.displayTarget),
                    subtitle: Text(
                      '${order.code} · ${Formatters.baht(order.total)}',
                    ),
                    onTap: () => Get.back(result: order.id),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text('common_close'.tr),
        ),
      ],
    );
  }
}
