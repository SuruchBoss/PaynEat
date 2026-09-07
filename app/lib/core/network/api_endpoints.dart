/// รวมทุก path ของ API ไว้ที่เดียว — แก้ครั้งเดียวมีผลทั้งแอป
class ApiEndpoints {
  const ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // Users
  static const String users = '/users';
  static String user(int id) => '/users/$id';
  static String resetPassword(int id) => '/users/$id/reset-password';

  // Categories
  static const String categories = '/categories';
  static String category(int id) => '/categories/$id';

  // Menu
  static const String menuItems = '/menu-items';
  static String menuItem(int id) => '/menu-items/$id';
  static String menuAvailability(int id) => '/menu-items/$id/availability';

  // Tables
  static const String tables = '/tables';
  static const String tableZones = '/tables/zones';
  static String table(int id) => '/tables/$id';
  static String tableStatus(int id) => '/tables/$id/status';

  // Orders
  static const String orders = '/orders';
  static const String kitchenQueue = '/orders/kitchen/queue';
  static String order(int id) => '/orders/$id';
  static String openOrderByTable(int tableId) => '/orders/table/$tableId/open';
  static String orderItems(int id) => '/orders/$id/items';
  static String orderItem(int orderId, int itemId) =>
      '/orders/$orderId/items/$itemId';
  static String orderItemStatus(int orderId, int itemId) =>
      '/orders/$orderId/items/$itemId/status';
  static String sendToKitchen(int id) => '/orders/$id/send-to-kitchen';
  static String orderDiscount(int id) => '/orders/$id/discount';
  static String cancelOrder(int id) => '/orders/$id/cancel';

  // Payments
  static const String payments = '/payments';
  static String paymentSummary(int orderId) => '/payments/order/$orderId';
  static String receipt(int orderId) => '/payments/order/$orderId/receipt';

  // Reports
  static const String dashboard = '/reports/dashboard';
  static const String reportSummary = '/reports/summary';
  static const String topItems = '/reports/top-items';
  static const String salesByDay = '/reports/sales-by-day';

  // Settings
  static const String settings = '/settings';
}
