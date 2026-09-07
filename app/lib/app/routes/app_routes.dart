/// ชื่อ route ทั้งหมดของแอป
abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';

  static const String newOrder = '/orders/new';
  static const String orderDetail = '/orders/detail';
  static const String checkout = '/checkout';
  static const String receipt = '/receipt';

  static const String menuForm = '/admin/menu/form';
  static const String staffForm = '/admin/staff/form';
  static const String tableForm = '/admin/tables/form';
}
