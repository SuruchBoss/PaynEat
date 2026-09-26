// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/customer.dart';
import '../controllers/customers_controller.dart';

/// รายชื่อลูกค้า/สมาชิกทั้งหมด (admin/manager) — ค้นหาแล้วกดดูประวัติรายคนได้
/// (ดู docs/tickets/09-customer-loyalty.md)
class CustomersPage extends GetView<CustomersController> {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TextField(
            onChanged: controller.search,
            decoration: InputDecoration(
              hintText: 'customer_list_search_hint'.tr,
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.customers.isEmpty) {
              return const LoadingView();
            }
            final error = controller.errorMessage.value;
            if (error != null && controller.customers.isEmpty) {
              return ErrorView(message: error, onRetry: controller.load);
            }
            if (controller.customers.isEmpty) {
              return EmptyView(
                message: 'customer_list_empty'.tr,
                icon: Icons.people_outline_rounded,
              );
            }

            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.customers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _CustomerTile(customer: controller.customers[index]),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Get.toNamed<void>(
          AppRoutes.customerDetail,
          arguments: {'customerId': customer.id},
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.brandInk,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      customer.phone,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'customer_list_points_badge'.trParams({
                  'points': '${customer.pointsBalance}',
                }),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandInk,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
