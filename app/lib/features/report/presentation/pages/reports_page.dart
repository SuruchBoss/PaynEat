import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../controllers/report_controller.dart';
import '../widgets/stat_card.dart';

/// รายงานยอดขายย้อนหลัง เลือกช่วงเวลาได้
class ReportsPage extends GetView<ReportController> {
  const ReportsPage({super.key});

  static const Map<ReportRange, String> _rangeLabels = {
    ReportRange.today: 'วันนี้',
    ReportRange.last7Days: '7 วันล่าสุด',
    ReportRange.thisMonth: 'เดือนนี้',
    ReportRange.custom: 'กำหนดเอง',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Obx(
            () => Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _rangeLabels.entries.map((entry) {
                      final selected = controller.range.value == entry.key;
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) => entry.key == ReportRange.custom
                            ? _pickCustomRange(context)
                            : controller.selectRange(entry.key),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceAlt,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  controller.fromLabel == controller.toLabel
                      ? controller.fromLabel
                      : '${controller.fromLabel} - ${controller.toLabel}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) return const LoadingView();

            final error = controller.errorMessage.value;
            if (error != null) return ErrorView(message: error, onRetry: controller.load);

            final summary = controller.summary.value;
            final columns = Responsive.value(context, mobile: 2, desktop: 4);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: Responsive.value(context, mobile: 1.45, desktop: 1.55),
                  children: [
                    StatCard(
                      label: 'ยอดขายสุทธิ',
                      value: Formatters.baht(summary.netSales),
                      icon: Icons.payments_rounded,
                      color: AppColors.success,
                    ),
                    StatCard(
                      label: 'จำนวนบิล',
                      value: '${summary.orderCount}',
                      caption: 'ลูกค้า ${summary.guestCount} ท่าน',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.info,
                    ),
                    StatCard(
                      label: 'ยอดอาหารก่อนภาษี',
                      value: Formatters.baht(summary.subtotal),
                      caption: 'Service ${Formatters.money(summary.serviceCharge)}',
                      icon: Icons.restaurant_rounded,
                      color: AppColors.primary,
                    ),
                    StatCard(
                      label: 'เฉลี่ยต่อบิล',
                      value: Formatters.baht(summary.averagePerOrder),
                      caption: 'ต่อหัว ${Formatters.baht(summary.averagePerGuest)}',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (controller.dailySales.length > 1) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'ยอดขายรายวัน'),
                        const SizedBox(height: 14),
                        _DailySalesList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'เมนูขายดี 10 อันดับ'),
                      const SizedBox(height: 8),
                      if (controller.topItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: Text(
                              'ไม่มีข้อมูลในช่วงที่เลือก',
                              style: TextStyle(color: AppColors.textDisabled, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        for (final entry in controller.topItems.asMap().entries)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 13,
                              backgroundColor: AppColors.surfaceAlt,
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            title: Text(
                              entry.value.name,
                              style: const TextStyle(fontSize: 13.5),
                            ),
                            subtitle: Text('${entry.value.quantity} จาน'),
                            trailing: Text(
                              Formatters.baht(entry.value.revenue),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'ยอดขายแยกตามหมวดหมู่'),
                      const SizedBox(height: 8),
                      if (summary.categories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: Text(
                              'ไม่มีข้อมูลในช่วงที่เลือก',
                              style: TextStyle(color: AppColors.textDisabled, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        for (final category in summary.categories)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    category.category,
                                    style: const TextStyle(fontSize: 13.5),
                                  ),
                                ),
                                Text(
                                  '${category.quantity} จาน',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textDisabled,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  Formatters.baht(category.revenue),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: controller.from, end: controller.to),
    );
    if (picked != null) {
      controller.setCustomRange(picked.start, picked.end);
    }
  }
}

class _DailySalesList extends GetView<ReportController> {
  @override
  Widget build(BuildContext context) {
    final data = controller.dailySales;
    final maxTotal = data.fold<double>(0, (max, item) => item.total > max ? item.total : max);

    return Column(
      children: data
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    child: Text(
                      item.day.substring(5),
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxTotal == 0 ? 0 : item.total / maxTotal,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceAlt,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 88,
                    child: Text(
                      Formatters.baht(item.total),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
