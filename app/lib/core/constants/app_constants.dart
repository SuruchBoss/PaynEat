/// บทบาทของผู้ใช้ในระบบ — ตรงกับ enum ฝั่ง backend
class UserRole {
  const UserRole._();

  static const String admin = 'admin';
  static const String manager = 'manager';
  static const String waiter = 'waiter';
  static const String cashier = 'cashier';
  static const String kitchen = 'kitchen';

  static const List<String> all = [admin, manager, waiter, cashier, kitchen];

  static const Map<String, String> labels = {
    admin: 'ผู้ดูแลระบบ',
    manager: 'ผู้จัดการ',
    waiter: 'พนักงานเสิร์ฟ',
    cashier: 'แคชเชียร์',
    kitchen: 'ครัว',
  };

  static String label(String role) => labels[role] ?? role;

  static bool isManagement(String role) => role == admin || role == manager;
  static bool canTakeOrder(String role) =>
      role == admin || role == manager || role == waiter || role == cashier;
  static bool canCollectPayment(String role) =>
      role == admin || role == manager || role == cashier || role == waiter;
  static bool canSeeReports(String role) =>
      role == admin || role == manager || role == cashier;
}

/// สถานะโต๊ะ
class TableStatus {
  const TableStatus._();

  static const String available = 'available';
  static const String occupied = 'occupied';
  static const String reserved = 'reserved';
  static const String billing = 'billing';

  static const List<String> all = [available, occupied, reserved, billing];

  static const Map<String, String> labels = {
    available: 'ว่าง',
    occupied: 'มีลูกค้า',
    reserved: 'จองแล้ว',
    billing: 'เรียกเก็บเงิน',
  };

  static String label(String status) => labels[status] ?? status;
}

/// สถานะออเดอร์
class OrderStatus {
  const OrderStatus._();

  static const String open = 'open';
  static const String inKitchen = 'in_kitchen';
  static const String served = 'served';
  static const String paid = 'paid';
  static const String cancelled = 'cancelled';

  static const Map<String, String> labels = {
    open: 'เปิดออเดอร์',
    inKitchen: 'ส่งครัวแล้ว',
    served: 'เสิร์ฟครบ',
    paid: 'ชำระเงินแล้ว',
    cancelled: 'ยกเลิก',
  };

  static String label(String status) => labels[status] ?? status;

  static bool isActive(String status) =>
      status == open || status == inKitchen || status == served;
}

/// สถานะรายการอาหารในออเดอร์ (ใช้กับจอครัว)
class OrderItemStatus {
  const OrderItemStatus._();

  static const String pending = 'pending';
  static const String cooking = 'cooking';
  static const String ready = 'ready';
  static const String served = 'served';
  static const String cancelled = 'cancelled';

  static const Map<String, String> labels = {
    pending: 'รอทำ',
    cooking: 'กำลังทำ',
    ready: 'พร้อมเสิร์ฟ',
    served: 'เสิร์ฟแล้ว',
    cancelled: 'ยกเลิก',
  };

  static String label(String status) => labels[status] ?? status;

  /// สถานะถัดไปที่กดได้จากหน้าจอครัว/พนักงานเสิร์ฟ
  static String? next(String status) {
    switch (status) {
      case pending:
        return cooking;
      case cooking:
        return ready;
      case ready:
        return served;
      default:
        return null;
    }
  }

  static String? nextActionLabel(String status) {
    switch (status) {
      case pending:
        return 'เริ่มทำ';
      case cooking:
        return 'ทำเสร็จแล้ว';
      case ready:
        return 'เสิร์ฟแล้ว';
      default:
        return null;
    }
  }
}

/// ประเภทออเดอร์
class OrderType {
  const OrderType._();

  static const String dineIn = 'dine_in';
  static const String takeaway = 'takeaway';
  static const String delivery = 'delivery';

  static const Map<String, String> labels = {
    dineIn: 'ทานที่ร้าน',
    takeaway: 'กลับบ้าน',
    delivery: 'เดลิเวอรี',
  };

  static String label(String type) => labels[type] ?? type;
}

/// ช่องทางชำระเงิน
class PaymentMethod {
  const PaymentMethod._();

  static const String cash = 'cash';
  static const String qr = 'qr';
  static const String card = 'card';
  static const String transfer = 'transfer';

  static const List<String> all = [cash, qr, card, transfer];

  static const Map<String, String> labels = {
    cash: 'เงินสด',
    qr: 'พร้อมเพย์ / QR',
    card: 'บัตรเครดิต',
    transfer: 'โอนเงิน',
  };

  static String label(String method) => labels[method] ?? method;
}

/// ชนิดส่วนลด
class DiscountType {
  const DiscountType._();

  static const String none = 'none';
  static const String amount = 'amount';
  static const String percent = 'percent';
}

/// คีย์ที่ใช้เก็บข้อมูลใน local storage
class StorageKeys {
  const StorageKeys._();

  static const String token = 'auth_token';
  static const String user = 'auth_user';
}
