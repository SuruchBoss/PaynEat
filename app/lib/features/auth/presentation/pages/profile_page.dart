import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/theme/app_colors.dart';
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
                foregroundColor: AppColors.danger,
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
