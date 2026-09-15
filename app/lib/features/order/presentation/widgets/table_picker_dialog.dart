import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../table/domain/entities/dining_table.dart';

/// กล่องเลือกโต๊ะปลายทาง — ใช้ตอนย้ายโต๊ะ
class TablePickerDialog extends StatelessWidget {
  const TablePickerDialog({super.key, required this.tables});

  final List<DiningTable> tables;

  static Future<int?> show(List<DiningTable> tables) =>
      Get.dialog<int>(TablePickerDialog(tables: tables));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('order_move_table_picker_title'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: tables.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('order_move_table_picker_empty'.tr),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: tables.length,
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return ListTile(
                    leading: const Icon(Icons.table_bar_rounded),
                    title: Text(table.name),
                    subtitle: Text(
                      'order_table_seats_summary'.trParams({
                        'zone': table.zone,
                        'seats': '${table.seats}',
                      }),
                    ),
                    onTap: () => Get.back(result: table.id),
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
