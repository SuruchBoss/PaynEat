import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/horizontal_fade.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/dining_table.dart';
import '../controllers/table_controller.dart';
import '../widgets/table_card.dart';

/// ผังโต๊ะ — หน้าจอหลักของพนักงานเสิร์ฟ
class TablesPage extends GetView<TableController> {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TableSummaryBar(),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.tables.isEmpty) {
              return LoadingView(message: 'table_loading_message'.tr);
            }
            final error = controller.errorMessage.value;
            if (error != null && controller.tables.isEmpty) {
              return ErrorView(message: error, onRetry: controller.loadTables);
            }

            final tables = controller.filteredTables;
            if (tables.isEmpty) {
              return EmptyView(
                message: 'table_empty_filtered_message'.tr,
                icon: Icons.table_restaurant_outlined,
              );
            }

            return RefreshIndicator(
              onRefresh: controller.loadTables,
              child: _TableGrid(tables: tables),
            );
          }),
        ),
      ],
    );
  }
}

class _TableGrid extends StatelessWidget {
  const _TableGrid({required this.tables});

  final List<DiningTable> tables;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TableController>();

    // จัดกลุ่มตามโซน เพื่อให้พนักงานหาโต๊ะได้เหมือนเดินในร้านจริง
    final grouped = <String, List<DiningTable>>{};
    for (final table in tables) {
      grouped.putIfAbsent(table.zone, () => []).add(table);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Responsive.gridColumns(
          constraints.maxWidth - 32,
          minTileWidth: 150,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 10),
                child: Row(
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'table_count_in_zone'.trParams({
                        'count': entry.value.length.toString(),
                      }),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entry.value.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final table = entry.value[index];
                  return TableCard(
                    table: table,
                    onTap: () => controller.openTable(table),
                    onLongPress: () =>
                        _showStatusSheet(context, controller, table),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  void _showStatusSheet(
    BuildContext context,
    TableController controller,
    DiningTable table,
  ) {
    Get.bottomSheet<void>(
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'table_number_label'.trParams({'name': table.name}),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${'table_seat_count'.trParams({'count': table.seats.toString()})} · ${table.zone}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (final status in TableStatus.all)
                ListTile(
                  leading: Icon(
                    Icons.circle,
                    size: 12,
                    color: AppColors.tableStatus(status),
                  ),
                  title: Text(TableStatus.label(status)),
                  trailing: table.status == status
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    Get.back<void>();
                    if (table.status != status) {
                      controller.changeStatus(table, status);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// แถบสรุปด้านบน + ตัวกรองโซน
class _TableSummaryBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TableController>();

    return Obx(
      () => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: AppColors.surface,
        child: Column(
          children: [
            Row(
              children: [
                // ดึงสีจาก tableStatus() จุดเดียวกับที่การ์ดโต๊ะใช้ ไม่ระบุสีตรง ๆ ซ้ำอีกที่
                // ไม่งั้นแถบสรุปด้านบนจะเพี้ยนจากผังโต๊ะด้านล่างทันทีที่สีสถานะถูกแก้
                _CounterPill(
                  label: 'table_available_count_label'.tr,
                  value: '${controller.availableCount}',
                  color: AppColors.tableStatus(TableStatus.available),
                ),
                const SizedBox(width: 10),
                _CounterPill(
                  label: 'table_occupied_count_label'.tr,
                  value: '${controller.occupiedCount}',
                  color: AppColors.tableStatus(TableStatus.occupied),
                ),
                const Spacer(),
                IconButton(
                  onPressed: controller.loadTables,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'table_refresh_tooltip'.tr,
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: HorizontalFade(
                builder: (context, scrollController) => ListView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChipItem(
                      label: 'table_all_zones_filter'.tr,
                      selected: controller.selectedZone.value == null,
                      onTap: () => controller.filterByZone(null),
                    ),
                    for (final zone in controller.zones)
                      _FilterChipItem(
                        label: zone,
                        selected: controller.selectedZone.value == zone,
                        onTap: () => controller.filterByZone(zone),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12.5, color: color)),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceAlt,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
