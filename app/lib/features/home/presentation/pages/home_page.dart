import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';

/// โครงหน้าหลักของแอป
///
/// - มือถือ: แถบเมนูล่าง (หรือลิ้นชักด้านข้างถ้าเมนูเยอะ เช่น บัญชีแอดมิน)
/// - แท็บเล็ต/เว็บ: NavigationRail ด้านซ้าย ขยายเป็นเมนูเต็มบนจอกว้าง
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  static const int _bottomNavLimit = 5;

  @override
  Widget build(BuildContext context) {
    final device = Responsive.of(context);
    final useRail = device != DeviceType.mobile;
    final useDrawer =
        !useRail && controller.destinations.length > _bottomNavLimit;

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: Text(controller.currentTitle),
          actions: const [
            _ConnectionDot(),
            SizedBox(width: 8),
            _UserChip(),
            SizedBox(width: 8),
          ],
        ),
        drawer: useDrawer ? _AppDrawer() : null,
        body: Row(
          children: [
            if (useRail)
              _NavigationRailSection(extended: device == DeviceType.desktop),
            Expanded(
              child: IndexedStack(
                index: controller.currentIndex.value,
                children: controller.destinations
                    .map((destination) => destination.page)
                    .toList(growable: false),
              ),
            ),
          ],
        ),
        bottomNavigationBar: useRail || useDrawer ? null : _BottomNav(),
      ),
    );
  }
}

class _NavigationRailSection extends GetView<HomeController> {
  const _NavigationRailSection({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 56,
        ),
        child: IntrinsicHeight(
          child: NavigationRail(
            extended: extended,
            minExtendedWidth: 210,
            backgroundColor: Colors.white,
            selectedIndex: controller.currentIndex.value,
            onDestinationSelected: controller.changeTab,
            labelType: extended ? null : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.primary,
                size: extended ? 30 : 26,
              ),
            ),
            destinations: controller.destinations
                .map(
                  (destination) => NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: controller.currentIndex.value,
      onDestinationSelected: controller.changeTab,
      height: 64,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primarySoft,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: controller.destinations
          .map(
            (destination) => NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(
                destination.selectedIcon,
                color: AppColors.primary,
              ),
              label: destination.label,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _AppDrawer extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: controller.currentIndex.value,
      onDestinationSelected: (index) {
        controller.changeTab(index);
        Get.back<void>();
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
          child: Row(
            children: [
              const Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.primary,
                size: 26,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PaynEat POS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    controller.user?.roleLabel ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        ...controller.destinations.map(
          (destination) => NavigationDrawerDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label),
          ),
        ),
      ],
    );
  }
}

/// ไฟบอกสถานะการเชื่อมต่อ socket — ให้พนักงานรู้ทันทีถ้าเน็ตหลุด
class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot();

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();

    return ValueListenableBuilder<bool>(
      valueListenable: session.socket.connected,
      builder: (context, connected, _) => Tooltip(
        message: connected
            ? 'เชื่อมต่อเรียลไทม์อยู่'
            : 'ไม่ได้เชื่อมต่อเรียลไทม์',
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: connected ? AppColors.success : AppColors.textDisabled,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _UserChip extends GetView<HomeController> {
  const _UserChip();

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: user.name,
      offset: const Offset(0, 46),
      onSelected: (value) {
        if (value == 'logout') Get.find<AuthController>().signOut();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(user.roleLabel),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.logout_rounded,
              size: 19,
              color: AppColors.danger,
            ),
            title: Text(
              'ออกจากระบบ',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 15,
        backgroundColor: AppColors.primarySoft,
        child: Text(
          user.initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
