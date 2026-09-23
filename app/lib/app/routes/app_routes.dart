/// ชื่อ route ทั้งหมดของแอป
abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String branchSelection = '/login/select-branch';
  static const String home = '/home';

  static const String newOrder = '/orders/new';
  static const String orderDetail = '/orders/detail';
  static const String checkout = '/checkout';
  static const String splitBill = '/checkout/split-bill';
  static const String receipt = '/receipt';
  static const String shift = '/shift';

  static const String menuForm = '/admin/menu/form';
  static const String staffForm = '/admin/staff/form';
  static const String tableForm = '/admin/tables/form';
  static const String promotionForm = '/admin/promotions/form';
  static const String ingredientForm = '/admin/ingredients/form';
  static const String customerDetail = '/admin/customers/detail';
  static const String customerStatement = '/receivables/statement';

  // ลูกค้าสแกน QR ที่โต๊ะแล้วสั่งอาหารเอง — ไม่ต้อง login เลย (ดู docs/tickets/17-qr-self-order.md)
  static const String selfOrder = '/order/:qrToken';
}
