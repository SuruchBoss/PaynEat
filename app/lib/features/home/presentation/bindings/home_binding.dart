import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/printing/receipt_printer_service.dart';
import '../../../../core/services/printer_settings_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../../../kitchen/presentation/controllers/kitchen_controller.dart';
import '../../../kitchen/presentation/pages/kitchen_page.dart';
import '../../../menu/domain/usecases/menu_usecases.dart';
import '../../../menu/presentation/controllers/menu_management_controller.dart';
import '../../../menu/presentation/pages/menu_management_page.dart';
import '../../../order/domain/usecases/order_usecases.dart';
import '../../../order/presentation/controllers/order_list_controller.dart';
import '../../../order/presentation/pages/orders_page.dart';
import '../../../promotion/domain/usecases/promotion_usecases.dart';
import '../../../promotion/presentation/controllers/promotions_controller.dart';
import '../../../promotion/presentation/pages/promotions_page.dart';
import '../../../report/domain/usecases/report_usecases.dart';
import '../../../report/presentation/controllers/dashboard_controller.dart';
import '../../../report/presentation/controllers/report_controller.dart';
import '../../../report/presentation/pages/dashboard_page.dart';
import '../../../report/presentation/pages/reports_page.dart';
import '../../../settings/domain/usecases/settings_usecases.dart';
import '../../../settings/presentation/controllers/printer_settings_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../shift/presentation/pages/shift_page.dart';
import '../../../staff/domain/usecases/staff_usecases.dart';
import '../../../staff/presentation/controllers/staff_controller.dart';
import '../../../staff/presentation/pages/staff_page.dart';
import '../../../table/domain/usecases/table_usecases.dart';
import '../../../table/presentation/controllers/table_controller.dart';
import '../../../table/presentation/pages/tables_page.dart';
import '../controllers/home_controller.dart';

/// DI ของหน้าหลัก
///
/// controller ของแต่ละแท็บใช้ `lazyPut` จึงถูกสร้างเมื่อผู้ใช้เปิดแท็บนั้นจริง ๆ เท่านั้น
/// (บัญชีครัวไม่ต้องเสียแรงโหลดข้อมูลรายงาน)
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    _bindTabControllers();

    Get.put<HomeController>(
      HomeController(
        session: Get.find<SessionService>(),
        destinationsBuilder: destinationsForRole,
      ),
    );
  }

  void _bindTabControllers() {
    Get.lazyPut(
      () => TableController(
        getTables: Get.find<GetTablesUseCase>(),
        setTableStatus: Get.find<SetTableStatusUseCase>(),
        session: Get.find<SessionService>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => OrderListController(
        getOrders: Get.find<GetOrdersUseCase>(),
        session: Get.find<SessionService>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => KitchenController(
        getQueue: Get.find<GetKitchenQueueUseCase>(),
        updateItemStatus: Get.find<UpdateOrderItemStatusUseCase>(),
        session: Get.find<SessionService>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => DashboardController(
        getDashboard: Get.find<GetDashboardUseCase>(),
        session: Get.find<SessionService>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => ReportController(
        getSummary: Get.find<GetSalesSummaryUseCase>(),
        getTopItems: Get.find<GetTopItemsUseCase>(),
        getSalesByDay: Get.find<GetSalesByDayUseCase>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => MenuManagementController(
        getMenuItems: Get.find<GetMenuItemsUseCase>(),
        getCategories: Get.find<GetCategoriesUseCase>(),
        createMenuItem: Get.find<CreateMenuItemUseCase>(),
        updateMenuItem: Get.find<UpdateMenuItemUseCase>(),
        deleteMenuItem: Get.find<DeleteMenuItemUseCase>(),
        toggleAvailability: Get.find<ToggleMenuAvailabilityUseCase>(),
        saveCategory: Get.find<SaveCategoryUseCase>(),
        deleteCategory: Get.find<DeleteCategoryUseCase>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => PromotionsController(
        getPromotions: Get.find<GetPromotionsUseCase>(),
        savePromotion: Get.find<SavePromotionUseCase>(),
        setPromotionActive: Get.find<SetPromotionActiveUseCase>(),
        deletePromotion: Get.find<DeletePromotionUseCase>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => StaffController(
        getStaff: Get.find<GetStaffUseCase>(),
        createStaff: Get.find<CreateStaffUseCase>(),
        updateStaff: Get.find<UpdateStaffUseCase>(),
        deleteStaff: Get.find<DeleteStaffUseCase>(),
        session: Get.find<SessionService>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => SettingsController(
        getSettings: Get.find<GetSettingsUseCase>(),
        updateSettings: Get.find<UpdateSettingsUseCase>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => PrinterSettingsController(
        settingsService: Get.find<PrinterSettingsService>(),
        printerService: Get.find<ReceiptPrinterService>(),
      ),
      fenix: true,
    );
  }

  /// เมนูที่แต่ละบทบาทเห็น — เป็นฟังก์ชันบริสุทธิ์จึงเขียนเทสต์ได้ง่าย
  static List<HomeDestination> destinationsForRole(String role) {
    // labels are translation keys — resolved with `.tr` where they are
    // displayed (AppBar title, nav rail/bar/drawer) so they stay in sync
    // when the user switches language at runtime.
    const tables = HomeDestination(
      label: 'home_nav_tables',
      icon: Icons.table_restaurant_outlined,
      selectedIcon: Icons.table_restaurant_rounded,
      page: TablesPage(),
    );
    const orders = HomeDestination(
      label: 'home_nav_orders',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      page: OrdersPage(),
    );
    const kitchen = HomeDestination(
      label: 'home_nav_kitchen',
      icon: Icons.soup_kitchen_outlined,
      selectedIcon: Icons.soup_kitchen_rounded,
      page: KitchenPage(),
    );
    const dashboard = HomeDestination(
      label: 'home_nav_dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      page: DashboardPage(),
    );
    const menu = HomeDestination(
      label: 'home_nav_menu',
      icon: Icons.restaurant_menu_outlined,
      selectedIcon: Icons.restaurant_menu_rounded,
      page: MenuManagementPage(),
    );
    const promotions = HomeDestination(
      label: 'home_nav_promotions',
      icon: Icons.local_offer_outlined,
      selectedIcon: Icons.local_offer_rounded,
      page: PromotionsPage(),
    );
    const staff = HomeDestination(
      label: 'home_nav_staff',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      page: StaffPage(),
    );
    const reports = HomeDestination(
      label: 'home_nav_reports',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      page: ReportsPage(),
    );
    const settings = HomeDestination(
      label: 'home_nav_settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      page: SettingsPage(),
    );
    const profile = HomeDestination(
      label: 'home_nav_profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      page: ProfilePage(),
    );
    const shift = HomeDestination(
      label: 'home_nav_shift',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale_rounded,
      page: ShiftPage(),
    );

    return switch (role) {
      UserRole.admin || UserRole.manager => const [
        dashboard,
        tables,
        orders,
        kitchen,
        menu,
        promotions,
        staff,
        reports,
        shift,
        settings,
        profile,
      ],
      UserRole.cashier => const [tables, orders, shift, reports, profile],
      UserRole.kitchen => const [kitchen, profile],
      _ => const [tables, orders, kitchen, profile],
    };
  }
}
