import 'package:get/get.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/bindings/home_binding.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/menu/presentation/pages/menu_form_page.dart';
import '../../features/order/presentation/bindings/order_bindings.dart';
import '../../features/order/presentation/pages/order_detail_page.dart';
import '../../features/order/presentation/pages/order_taking_page.dart';
import '../../features/payment/presentation/bindings/payment_bindings.dart';
import '../../features/payment/presentation/pages/checkout_page.dart';
import '../../features/payment/presentation/pages/receipt_page.dart';
import '../../features/payment/presentation/pages/split_bill_page.dart';
import '../../features/promotion/presentation/pages/promotion_form_page.dart';
import '../../features/shift/presentation/pages/shift_page.dart';
import 'app_routes.dart';

/// ตารางเส้นทางของแอป — ผูก route → หน้าจอ → binding (DI เฉพาะของหน้านั้น)
class AppPages {
  const AppPages._();

  static final List<GetPage<dynamic>> pages = [
    GetPage<void>(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage<void>(name: AppRoutes.login, page: () => const LoginPage()),
    GetPage<void>(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage<void>(
      name: AppRoutes.newOrder,
      page: () => const OrderTakingPage(),
      binding: OrderTakingBinding(),
    ),
    GetPage<void>(
      name: AppRoutes.orderDetail,
      page: () => const OrderDetailPage(),
      binding: OrderDetailBinding(),
    ),
    GetPage<void>(
      name: AppRoutes.checkout,
      page: () => const CheckoutPage(),
      binding: CheckoutBinding(),
    ),
    GetPage<void>(
      name: AppRoutes.splitBill,
      page: () => const SplitBillPage(),
      binding: SplitBillBinding(),
    ),
    GetPage<void>(
      name: AppRoutes.receipt,
      page: () => const ReceiptPage(),
      binding: ReceiptBinding(),
    ),
    GetPage<void>(name: AppRoutes.menuForm, page: () => const MenuFormPage()),
    GetPage<void>(
      name: AppRoutes.promotionForm,
      page: () => const PromotionFormPage(),
    ),
    GetPage<void>(name: AppRoutes.shift, page: () => const ShiftPage()),
  ];
}
