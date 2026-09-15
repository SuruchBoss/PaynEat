/// ป้ายชื่อสถานะ/enum ต่างๆ ที่มาจาก [AppConstants] — โต๊ะ, ออเดอร์, การชำระเงิน ฯลฯ
const Map<String, String> statusTranslationsTh = {
  'role_admin': 'ผู้ดูแลระบบ',
  'role_manager': 'ผู้จัดการ',
  'role_waiter': 'พนักงานเสิร์ฟ',
  'role_cashier': 'แคชเชียร์',
  'role_kitchen': 'ครัว',

  'table_status_available': 'ว่าง',
  'table_status_occupied': 'มีลูกค้า',
  'table_status_reserved': 'จองแล้ว',
  'table_status_billing': 'เรียกเก็บเงิน',

  'order_status_open': 'เปิดออเดอร์',
  'order_status_in_kitchen': 'ส่งครัวแล้ว',
  'order_status_served': 'เสิร์ฟครบ',
  'order_status_paid': 'ชำระเงินแล้ว',
  'order_status_cancelled': 'ยกเลิก',

  'order_item_status_pending': 'รอทำ',
  'order_item_status_cooking': 'กำลังทำ',
  'order_item_status_ready': 'พร้อมเสิร์ฟ',
  'order_item_status_served': 'เสิร์ฟแล้ว',
  'order_item_status_cancelled': 'ยกเลิก',
  'order_item_next_action_pending': 'เริ่มทำ',
  'order_item_next_action_cooking': 'ทำเสร็จแล้ว',
  'order_item_next_action_ready': 'เสิร์ฟแล้ว',

  'order_type_dine_in': 'ทานที่ร้าน',
  'order_type_takeaway': 'กลับบ้าน',
  'order_type_delivery': 'เดลิเวอรี',

  'payment_method_cash': 'เงินสด',
  'payment_method_qr': 'พร้อมเพย์ / QR',
  'payment_method_card': 'บัตรเครดิต',
  'payment_method_transfer': 'โอนเงิน',
};

const Map<String, String> statusTranslationsEn = {
  'role_admin': 'Admin',
  'role_manager': 'Manager',
  'role_waiter': 'Waiter',
  'role_cashier': 'Cashier',
  'role_kitchen': 'Kitchen',

  'table_status_available': 'Available',
  'table_status_occupied': 'Occupied',
  'table_status_reserved': 'Reserved',
  'table_status_billing': 'Billing',

  'order_status_open': 'Open',
  'order_status_in_kitchen': 'Sent to kitchen',
  'order_status_served': 'Served',
  'order_status_paid': 'Paid',
  'order_status_cancelled': 'Cancelled',

  'order_item_status_pending': 'Pending',
  'order_item_status_cooking': 'Cooking',
  'order_item_status_ready': 'Ready',
  'order_item_status_served': 'Served',
  'order_item_status_cancelled': 'Cancelled',
  'order_item_next_action_pending': 'Start cooking',
  'order_item_next_action_cooking': 'Mark ready',
  'order_item_next_action_ready': 'Mark served',

  'order_type_dine_in': 'Dine in',
  'order_type_takeaway': 'Takeaway',
  'order_type_delivery': 'Delivery',

  'payment_method_cash': 'Cash',
  'payment_method_qr': 'PromptPay / QR',
  'payment_method_card': 'Credit card',
  'payment_method_transfer': 'Bank transfer',
};
