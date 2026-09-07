import 'package:get/get.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import 'app_routes.dart';

/// ตารางเส้นทางของแอป — ผูก route → หน้าจอ → binding (DI ของหน้านั้น)
class AppPages {
  const AppPages._();

  static final List<GetPage<dynamic>> pages = [
    GetPage<void>(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage<void>(name: AppRoutes.login, page: () => const LoginPage()),
  ];
}
