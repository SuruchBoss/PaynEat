import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/auth_controller.dart';

/// เลือกสาขาที่จะทำงานตอน login ครั้งแรก (ดู docs/tickets/11-multi-branch.md) — เห็นเฉพาะ user
/// ที่มีสิทธิ์เข้ามากกว่า 1 สาขาเท่านั้น (คนอื่น/admin ข้ามหน้านี้ไปเลย)
class BranchSelectionPage extends GetView<AuthController> {
  const BranchSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('branch_selection_title'.tr)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'branch_selection_subtitle'.tr,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => Column(
                      children: controller.pendingBranches
                          .map(
                            (branch) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BranchTile(
                                name: branch.name,
                                address: branch.address,
                                enabled: !controller.isSelectingBranch.value,
                                onTap: () =>
                                    controller.submitBranchSelection(branch.id),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  Obx(
                    () => controller.isSelectingBranch.value
                        ? const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({
    required this.name,
    required this.address,
    required this.onTap,
    required this.enabled,
  });

  final String name;
  final String? address;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: AppColors.brandInk,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (address != null && address!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        address!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
