import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../controllers/auth_controller.dart';

/// ตัวเลือกบัญชีเดโม — กดแล้วกรอกให้อัตโนมัติ
/// (มีไว้เพื่อให้ผู้ที่มาดูผลงานลองใช้แต่ละบทบาทได้เร็ว)
class DemoAccountPicker extends GetView<AuthController> {
  const DemoAccountPicker({super.key});

  static const List<
    ({String label, String username, String password, IconData icon})
  >
  _accounts = [
    (
      label: 'พนักงานเสิร์ฟ',
      username: 'waiter1',
      password: 'waiter123',
      icon: Icons.room_service_rounded,
    ),
    (
      label: 'ครัว',
      username: 'kitchen',
      password: 'kitchen123',
      icon: Icons.soup_kitchen_rounded,
    ),
    (
      label: 'แคชเชียร์',
      username: 'cashier',
      password: 'cashier123',
      icon: Icons.point_of_sale_rounded,
    ),
    (
      label: 'ผู้ดูแลระบบ',
      username: 'admin',
      password: 'admin123',
      icon: Icons.admin_panel_settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'บัญชีทดลองใช้',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _accounts
                .map(
                  (account) => ActionChip(
                    avatar: Icon(
                      account.icon,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: Text(account.label),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () => controller.fillDemoAccount(
                      account.username,
                      account.password,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
