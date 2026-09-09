import 'package:get/get.dart';

import '../../core/demo/demo_data_sources.dart';
import '../../core/demo/demo_store.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_client.dart';
import '../../core/services/session_service.dart';
import '../../core/services/storage_service.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/change_password_usecase.dart';
import '../../features/auth/domain/usecases/get_profile_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/menu/data/datasources/menu_remote_data_source.dart';
import '../../features/menu/data/repositories/menu_repository_impl.dart';
import '../../features/menu/domain/repositories/menu_repository.dart';
import '../../features/menu/domain/usecases/menu_usecases.dart';
import '../../features/order/data/datasources/order_remote_data_source.dart';
import '../../features/order/data/repositories/order_repository_impl.dart';
import '../../features/order/domain/repositories/order_repository.dart';
import '../../features/order/domain/usecases/order_usecases.dart';
import '../../features/payment/data/datasources/payment_remote_data_source.dart';
import '../../features/payment/data/repositories/payment_repository_impl.dart';
import '../../features/payment/domain/repositories/payment_repository.dart';
import '../../features/payment/domain/usecases/payment_usecases.dart';
import '../../features/report/data/datasources/report_remote_data_source.dart';
import '../../features/report/data/repositories/report_repository_impl.dart';
import '../../features/report/domain/repositories/report_repository.dart';
import '../../features/report/domain/usecases/report_usecases.dart';
import '../../features/settings/data/datasources/settings_remote_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/settings_usecases.dart';
import '../../features/shift/data/datasources/shift_remote_data_source.dart';
import '../../features/shift/data/repositories/shift_repository_impl.dart';
import '../../features/shift/domain/repositories/shift_repository.dart';
import '../../features/shift/domain/usecases/shift_usecases.dart';
import '../../features/shift/presentation/controllers/shift_controller.dart';
import '../../features/staff/data/datasources/staff_remote_data_source.dart';
import '../../features/staff/data/repositories/staff_repository_impl.dart';
import '../../features/staff/domain/repositories/staff_repository.dart';
import '../../features/staff/domain/usecases/staff_usecases.dart';
import '../../features/table/data/datasources/table_remote_data_source.dart';
import '../../features/table/data/repositories/table_repository_impl.dart';
import '../../features/table/domain/repositories/table_repository.dart';
import '../../features/table/domain/usecases/table_usecases.dart';
import '../config/app_config.dart';

/// ประกอบ dependency ของทั้งแอปไว้ที่เดียว (composition root)
///
/// จุดสำคัญของ Clean Architecture: ชั้นบนรู้จักเฉพาะ abstract ส่วนตัวจริงถูกผูกที่นี่ที่เดียว
/// เปลี่ยนไปใช้ mock หรือ data source อื่นได้โดยไม่ต้องแตะโค้ดหน้าจอเลย
///
/// ใช้ `fenix: true` เพื่อให้ GetX สร้างใหม่อัตโนมัติหากถูกเก็บกวาดไปแล้วมีคนเรียกใช้อีก
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final storage = Get.find<StorageService>();

    _bindCore(storage);
    _bindDataSources();
    _bindRepositories(storage);
    _bindUseCases();
    _bindGlobalControllers();
  }

  void _bindCore(StorageService storage) {
    Get.put<SocketClient>(SocketClient(), permanent: true);
    Get.put<ApiClient>(
      ApiClient(
        tokenProvider: () => storage.token,
        onUnauthorized: () {
          if (Get.isRegistered<AuthController>()) {
            Get.find<AuthController>().handleSessionExpired();
          }
        },
      ),
      permanent: true,
    );
    Get.put<SessionService>(
      SessionService(storage: storage, socket: Get.find<SocketClient>()),
      permanent: true,
    );
  }

  void _bindDataSources() {
    if (AppConfig.demoMode) {
      _bindDemoDataSources();
      return;
    }

    final client = Get.find<ApiClient>();

    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(client),
      fenix: true,
    );
    Get.lazyPut<MenuRemoteDataSource>(
      () => MenuRemoteDataSourceImpl(client),
      fenix: true,
    );
    Get.lazyPut<TableRemoteDataSource>(
      () => TableRemoteDataSourceImpl(client),
      fenix: true,
    );
    Get.lazyPut<OrderRemoteDataSource>(
      () => OrderRemoteDataSourceImpl(client),
      fenix: true,
    );
    Get.lazyPut<PaymentRemoteDataSource>(
      () => PaymentRemoteDataSourceImpl(client),
      fenix: true,
    );
    Get.lazyPut<ReportRemoteDataSource>(
      () => ReportRemoteDataSourceImpl(client),
      fenix: true,
    );
    Get.lazyPut<StaffRemoteDataSource>(
      () => StaffRemoteDataSourceImpl(client),
      fenix: true,
    );
    Get.lazyPut<SettingsRemoteDataSource>(
      () => SettingsRemoteDataSourceImpl(client),
      fenix: true,
    );
    Get.lazyPut<ShiftRemoteDataSource>(
      () => ShiftRemoteDataSourceImpl(client),
      fenix: true,
    );
  }

  /// โหมดสาธิต: เปลี่ยนเฉพาะชั้น data source ชั้นอื่นทั้งหมดไม่ต้องแก้แม้แต่บรรทัดเดียว
  void _bindDemoDataSources() {
    final store = DemoStore.instance;
    final auth = DemoAuthDataSource(store);

    Get.put<AuthRemoteDataSource>(auth, permanent: true);
    Get.put<MenuRemoteDataSource>(DemoMenuDataSource(store), permanent: true);
    Get.put<TableRemoteDataSource>(DemoTableDataSource(store), permanent: true);
    Get.put<OrderRemoteDataSource>(
      DemoOrderDataSource(store, auth),
      permanent: true,
    );
    Get.put<PaymentRemoteDataSource>(
      DemoPaymentDataSource(store, auth),
      permanent: true,
    );
    Get.put<ReportRemoteDataSource>(
      DemoReportDataSource(store),
      permanent: true,
    );
    Get.put<StaffRemoteDataSource>(DemoStaffDataSource(store), permanent: true);
    Get.put<SettingsRemoteDataSource>(
      DemoSettingsDataSource(store),
      permanent: true,
    );
    Get.put<ShiftRemoteDataSource>(
      DemoShiftDataSource(store, auth),
      permanent: true,
    );
  }

  void _bindRepositories(StorageService storage) {
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: Get.find<AuthRemoteDataSource>(),
        storage: storage,
      ),
      fenix: true,
    );
    Get.lazyPut<MenuRepository>(
      () => MenuRepositoryImpl(Get.find<MenuRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut<TableRepository>(
      () => TableRepositoryImpl(Get.find<TableRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut<OrderRepository>(
      () => OrderRepositoryImpl(Get.find<OrderRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut<PaymentRepository>(
      () => PaymentRepositoryImpl(Get.find<PaymentRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut<ReportRepository>(
      () => ReportRepositoryImpl(Get.find<ReportRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut<StaffRepository>(
      () => StaffRepositoryImpl(Get.find<StaffRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut<SettingsRepository>(
      () => SettingsRepositoryImpl(Get.find<SettingsRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut<ShiftRepository>(
      () => ShiftRepositoryImpl(Get.find<ShiftRemoteDataSource>()),
      fenix: true,
    );
  }

  void _bindUseCases() {
    // auth
    Get.lazyPut(() => LoginUseCase(Get.find<AuthRepository>()), fenix: true);
    Get.lazyPut(
      () => GetProfileUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut(() => LogoutUseCase(Get.find<AuthRepository>()), fenix: true);
    Get.lazyPut(
      () => ChangePasswordUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );

    // menu
    Get.lazyPut(
      () => GetMenuItemsUseCase(Get.find<MenuRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetCategoriesUseCase(Get.find<MenuRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => CreateMenuItemUseCase(Get.find<MenuRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => UpdateMenuItemUseCase(Get.find<MenuRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => DeleteMenuItemUseCase(Get.find<MenuRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => ToggleMenuAvailabilityUseCase(Get.find<MenuRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => SaveCategoryUseCase(Get.find<MenuRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => DeleteCategoryUseCase(Get.find<MenuRepository>()),
      fenix: true,
    );

    // table
    Get.lazyPut(
      () => GetTablesUseCase(Get.find<TableRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => SetTableStatusUseCase(Get.find<TableRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => SaveTableUseCase(Get.find<TableRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => DeleteTableUseCase(Get.find<TableRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetZonesUseCase(Get.find<TableRepository>()),
      fenix: true,
    );

    // order
    Get.lazyPut(
      () => GetOrdersUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetOrderUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetOpenOrderByTableUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => CreateOrderUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => AddOrderItemsUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => UpdateOrderItemUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => RemoveOrderItemUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => UpdateOrderItemStatusUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => SendToKitchenUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => ApplyDiscountUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => CancelOrderUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => MoveOrderTableUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => MergeOrdersUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetKitchenQueueUseCase(Get.find<OrderRepository>()),
      fenix: true,
    );

    // payment
    Get.lazyPut(
      () => PayOrderUseCase(Get.find<PaymentRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetPaymentSummaryUseCase(Get.find<PaymentRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetSplitPreviewUseCase(Get.find<PaymentRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetReceiptUseCase(Get.find<PaymentRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => RefundPaymentUseCase(Get.find<PaymentRepository>()),
      fenix: true,
    );

    // shift
    Get.lazyPut(
      () => GetCurrentShiftUseCase(Get.find<ShiftRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => OpenShiftUseCase(Get.find<ShiftRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => CloseShiftUseCase(Get.find<ShiftRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetShiftHistoryUseCase(Get.find<ShiftRepository>()),
      fenix: true,
    );
    // lazyPut (ไม่ eager) เพราะ onInit ของ controller นี้ยิง API ทันที
    // ถ้าสร้างตอนแอปเริ่ม (ก่อนล็อกอิน) จะโดน 401 และอาจไปเข้าเงื่อนไข session
    // หมดอายุใน ApiClient ทั้งที่ผู้ใช้ยังไม่เคยล็อกอินเลย — ต้องรอให้มีคนเรียกใช้จริง
    // (เปิดแท็บ "กะ" หรือเข้าหน้าเก็บเงิน ซึ่งเกิดหลังล็อกอินเสมอ) ก่อนจะสร้าง
    Get.lazyPut(
      () => ShiftController(
        getCurrent: Get.find<GetCurrentShiftUseCase>(),
        openShift: Get.find<OpenShiftUseCase>(),
        closeShift: Get.find<CloseShiftUseCase>(),
        getHistory: Get.find<GetShiftHistoryUseCase>(),
      ),
      fenix: true,
    );

    // report
    Get.lazyPut(
      () => GetDashboardUseCase(Get.find<ReportRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetSalesSummaryUseCase(Get.find<ReportRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetTopItemsUseCase(Get.find<ReportRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetSalesByDayUseCase(Get.find<ReportRepository>()),
      fenix: true,
    );

    // staff
    Get.lazyPut(
      () => GetStaffUseCase(Get.find<StaffRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => CreateStaffUseCase(Get.find<StaffRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => UpdateStaffUseCase(Get.find<StaffRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => DeleteStaffUseCase(Get.find<StaffRepository>()),
      fenix: true,
    );

    // settings
    Get.lazyPut(
      () => GetSettingsUseCase(Get.find<SettingsRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => UpdateSettingsUseCase(Get.find<SettingsRepository>()),
      fenix: true,
    );
  }

  void _bindGlobalControllers() {
    Get.put<AuthController>(
      AuthController(
        loginUseCase: Get.find<LoginUseCase>(),
        getProfileUseCase: Get.find<GetProfileUseCase>(),
        logoutUseCase: Get.find<LogoutUseCase>(),
        repository: Get.find<AuthRepository>(),
        session: Get.find<SessionService>(),
      ),
      permanent: true,
    );
  }
}
