import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/report.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/hourly_bar_chart.dart';
import '../widgets/stat_card.dart';

/// แดชบอร์ดผู้จัดการ — สถานะร้าน ณ ตอนนี้: ยอดขายวันนี้ ช่วงเวลาขายดี และช่องทางชำระเงิน
/// (เมนูขายดีและการเทียบย้อนหลังอยู่ที่หน้ารายงาน เพื่อไม่ให้สองหน้าทำงานทับกัน)
class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return LoadingView(message: 'report_dashboard_loading'.tr);
      }
      final error = controller.errorMessage.value;
      if (error != null) {
        return ErrorView(message: error, onRetry: controller.load);
      }

      final data = controller.data.value;
      final today = data.today;
      final columns = Responsive.value(
        context,
        mobile: 2,
        tablet: 2,
        desktop: 4,
      );

      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _LiveBar(live: data.live),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: Responsive.value(
                context,
                mobile: 1.45,
                desktop: 1.55,
              ),
              children: [
                StatCard(
                  label: 'report_today_sales_label'.tr,
                  value: Formatters.baht(today.netSales),
                  caption: 'report_today_sales_caption'.tr,
                  icon: Icons.payments_rounded,
                  color: AppColors.success,
                ),
                StatCard(
                  label: 'report_order_count_label'.tr,
                  value: '${today.orderCount}',
                  caption: 'report_guest_count_caption'.trParams({
                    'count': today.guestCount.toString(),
                  }),
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.info,
                ),
                StatCard(
                  label: 'report_average_per_order_label'.tr,
                  value: Formatters.baht(today.averagePerOrder),
                  caption: 'report_average_per_guest_caption'.trParams({
                    'amount': Formatters.baht(today.averagePerGuest),
                  }),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.primary,
                ),
                StatCard(
                  label: 'report_discount_given_label'.tr,
                  value: Formatters.baht(today.discount),
                  caption: 'report_vat_caption'.trParams({
                    'amount': Formatters.money(today.vat),
                  }),
                  icon: Icons.local_offer_rounded,
                  color: AppColors.purple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'report_hourly_sales_title'.tr,
                    subtitle: 'report_hourly_sales_subtitle'.tr,
                  ),
                  const SizedBox(height: 16),
                  HourlyBarChart(data: data.hourly),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // "เมนูขายดี" ย้ายไปอยู่ที่หน้ารายงานที่เดียว — หน้าภาพรวมทำหน้าที่บอก
            // "สถานะร้าน ณ ตอนนี้" ส่วนหน้ารายงานไว้ดูย้อนหลังและเทียบช่วงเวลา
            // ก่อนหน้านี้ทั้งสองหน้าแสดงชุดข้อมูลเดียวกันเมื่อเลือกช่วง "วันนี้"
            _PaymentBreakdownCard(summary: today),
          ],
        ),
      );
    });
  }
}

class _LiveBar extends StatelessWidget {
  const _LiveBar({required this.live});

  final LiveCounters live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LiveItem(
              label: 'report_open_orders_label'.tr,
              value: '${live.openOrders}',
              icon: Icons.pending_actions_rounded,
            ),
          ),
          _divider(),
          Expanded(
            child: _LiveItem(
              label: 'report_occupied_tables_label'.tr,
              value: '${live.occupiedTables}/${live.totalTables}',
              icon: Icons.table_restaurant_rounded,
            ),
          ),
          _divider(),
          Expanded(
            child: _LiveItem(
              label: 'report_pending_kitchen_label'.tr,
              value: '${live.pendingKitchenItems}',
              icon: Icons.soup_kitchen_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 34,
    color: Colors.white.withValues(alpha: 0.25),
  );
}

class _LiveItem extends StatelessWidget {
  const _LiveItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 15),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _PaymentBreakdownCard extends StatelessWidget {
  const _PaymentBreakdownCard({required this.summary});

  final SalesSummary summary;

  @override
  Widget build(BuildContext context) {
    final methods = summary.paymentMethods;
    final total = methods.fold<double>(0, (sum, item) => sum + item.amount);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'report_payment_methods_title'.tr),
          const SizedBox(height: 12),
          if (methods.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'report_no_payments_yet'.tr,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            for (final entry in methods.asMap().entries) ...[
              Row(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.paymentMethod(entry.value.method),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value.label,
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                  Text(
                    'report_bill_count'.trParams({
                      'count': entry.value.count.toString(),
                    }),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Formatters.baht(entry.value.amount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : entry.value.amount / total,
                  minHeight: 5,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation(
                    AppColors.paymentMethod(entry.value.method),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}
