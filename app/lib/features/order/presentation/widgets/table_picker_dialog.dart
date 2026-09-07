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
      title: const Text('ย้ายไปโต๊ะไหน'),
      content: SizedBox(
        width: double.maxFinite,
        child: tables.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('ไม่มีโต๊ะว่างให้ย้ายตอนนี้'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: tables.length,
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return ListTile(
                    leading: const Icon(Icons.table_bar_rounded),
                    title: Text(table.name),
                    subtitle: Text('${table.zone} · ${table.seats} ที่นั่ง'),
                    onTap: () => Get.back(result: table.id),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back<void>(), child: const Text('ปิด')),
      ],
    );
  }
}
