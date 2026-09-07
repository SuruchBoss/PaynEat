import 'package:get/get.dart';

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

/// ประกอบ dependency ของทั้งแอปไว้ที่เดียว (composition root)
///
/// จุดสำคัญของ Clean Architecture: ชั้นบนรู้จักเฉพาะ abstract ส่วนตัวจริง
/// ถูกผูกที่นี่ที่เดียว — เปลี่ยนไปใช้ mock หรือ data source อื่นได้โดยไม่แตะโค้ดหน้าจอ
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final storage = Get.find<StorageService>();

    // ---------- core ----------
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

    // ---------- auth ----------
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: Get.find<AuthRemoteDataSource>(),
        storage: storage,
      ),
      fenix: true,
    );
    Get.lazyPut(() => LoginUseCase(Get.find<AuthRepository>()), fenix: true);
    Get.lazyPut(() => GetProfileUseCase(Get.find<AuthRepository>()), fenix: true);
    Get.lazyPut(() => LogoutUseCase(Get.find<AuthRepository>()), fenix: true);
    Get.lazyPut(() => ChangePasswordUseCase(Get.find<AuthRepository>()), fenix: true);

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
