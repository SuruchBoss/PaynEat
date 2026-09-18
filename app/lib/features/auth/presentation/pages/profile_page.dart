import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/locale_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/services/contrast_service.dart';

/// โปรไฟล์ผู้ใช้ปัจจุบัน + สถานะการเชื่อมต่อเรียลไทม์ + ปุ่มออกจากระบบ
class ProfilePage extends GetView<AuthController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();

    return Obx(() {
      final user = session.currentUserRx.value;
      if (user == null) return const SizedBox.shrink();

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AppCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      user.initials,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.roleLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // โหมดสาธิตไม่มี backend จริงให้เชื่อมต่อเลย — โชว์การ์ดนี้จะขึ้น "ไม่ได้เชื่อมต่อ"
          // ค้างตลอดพร้อม URL localhost ที่ไม่มีความหมายอะไรกับคนมาลองเดโมสาธารณะ
          // (เข้าใจผิดว่าแอปพังได้) จึงซ่อนไปเลยเมื่อ demoMode
          if (!AppConfig.demoMode) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(title: 'auth_profile_connection_title'.tr),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: session.socket.connected,
                      builder: (context, connected, _) => Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: connected
                                  ? AppColors.success
                                  : AppColors.textDisabled,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            connected
                                ? 'auth_profile_realtime_connected'.tr
                                : 'auth_profile_realtime_disconnected'.tr,
                            style: const TextStyle(fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConfig.baseUrl,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // โหมดสาธิตมีสาขาเดียวเท่านั้น (ดู docs/DECISIONS.md #36) สลับไปมาไม่มีความหมาย
          // จึงซ่อนการ์ดนี้เมื่อ demoMode เหมือนกับการ์ดเชื่อมต่อด้านบน
          if (!AppConfig.demoMode) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: const _BranchCard(),
            ),
          ],
          const SizedBox(height: 12),
          // ตัวสลับภาษาเคยอยู่แต่ในหน้าตั้งค่าซึ่งเป็นสิทธิ์ของแอดมิน แปลว่าพนักงานเสิร์ฟ
          // ครัว และแคชเชียร์ไม่มีทางเปลี่ยนภาษาได้เลยทั้งที่แอปรองรับสองภาษา
          // หน้านี้เป็นหน้าเดียวที่ทุกบทบาทเข้าถึงได้ จึงเป็นที่ที่ควรอยู่
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: const _LanguageCard(),
          ),
          const SizedBox(height: 12),
          // โหมดคอนทราสต์สูงต้องอยู่ที่นี่ด้วยเหตุผลเดียวกับตัวสลับภาษา — คนที่ต้องใช้
          // จริงคือพนักงานครัวกับพนักงานเสิร์ฟ ซึ่งเข้าหน้าตั้งค่าของแอดมินไม่ได้
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: const _ContrastCard(),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: OutlinedButton.icon(
              onPressed: controller.signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dangerInk,
                side: const BorderSide(color: AppColors.danger),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text('auth_logout'.tr),
            ),
          ),
        ],
      );
    });
  }
}

/// การ์ดเลือกภาษา — ใช้ SegmentedButton ชุดเดียวกับหน้าตั้งค่า
class _LanguageCard extends StatefulWidget {
  const _LanguageCard();

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard> {
  @override
  Widget build(BuildContext context) {
    final isEnglish = LocaleService.isEnglish;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'settings_language_title'.tr),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text('settings_language_th'.tr),
              ),
              ButtonSegment(
                value: true,
                label: Text('settings_language_en'.tr),
              ),
            ],
            selected: {isEnglish},
            onSelectionChanged: (selection) async {
              await LocaleService.change(
                selection.first
                    ? const Locale('en', 'US')
                    : const Locale('th', 'TH'),
              );
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

/// การ์ดเลือกระดับคอนทราสต์ — สำหรับจอที่ต้องอ่านกลางแดดหรือในครัว
class _ContrastCard extends StatefulWidget {
  const _ContrastCard();

  @override
  State<_ContrastCard> createState() => _ContrastCardState();
}

class _ContrastCardState extends State<_ContrastCard> {
  @override
  Widget build(BuildContext context) {
    final isHigh = ContrastService.isHigh;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'settings_contrast_title'.tr,
            subtitle: 'settings_contrast_subtitle'.tr,
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text('settings_contrast_standard'.tr),
              ),
              ButtonSegment(
                value: true,
                label: Text('settings_contrast_high'.tr),
              ),
            ],
            selected: {isHigh},
            onSelectionChanged: (selection) async {
              await ContrastService.change(selection.first);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

/// การ์ดสาขาปัจจุบัน + ปุ่มสลับสาขา (ดู docs/tickets/11-multi-branch.md) — เห็นเฉพาะโหมดที่ต่อ
/// backend จริงเท่านั้น (โหมดสาธิตมีสาขาเดียว ซ่อนไปทั้งการ์ด ดู docs/DECISIONS.md #36)
class _BranchCard extends GetView<AuthController> {
  const _BranchCard();

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();

    return Obx(() {
      final user = session.currentUserRx.value;
      final branchLabel = user?.branchName ?? 'branch_all_branches'.tr;
      final switching = controller.isSwitchingBranch.value;

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'branch_current_label'.tr),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.storefront_rounded,
                  size: 18,
                  color: AppColors.brandInk,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    branchLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (switching)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                else
                  TextButton(
                    onPressed: () => _openSwitcher(context, user?.role),
                    child: Text('branch_switch_action'.tr),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Future<void> _openSwitcher(BuildContext context, String? role) async {
    await controller.loadMyBranches();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Obx(() {
          if (controller.isLoadingMyBranches.value) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            );
          }
          final branches = controller.myBranches;
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              if (role == UserRole.admin)
                ListTile(
                  leading: const Icon(Icons.apartment_rounded),
                  title: Text('branch_all_branches'.tr),
                  onTap: () {
                    Get.back<void>();
                    controller.switchBranch(null);
                  },
                ),
              ...branches.map(
                (branch) => ListTile(
                  leading: const Icon(Icons.storefront_rounded),
                  title: Text(branch.name),
                  subtitle: (branch.address?.isNotEmpty ?? false)
                      ? Text(branch.address!)
                      : null,
                  onTap: () {
                    Get.back<void>();
                    controller.switchBranch(branch.id);
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
