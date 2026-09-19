/// คำแปลของฟีเจอร์สั่งอาหารเองผ่าน QR (ดู docs/tickets/17-qr-self-order.md)
const Map<String, String> selfOrderTranslationsTh = {
  'self_order_title': 'สั่งอาหาร',
  'self_order_loading': 'กำลังโหลดเมนู...',
  'self_order_invalid_link': 'ลิงก์ไม่ถูกต้อง กรุณาสแกน QR ที่โต๊ะใหม่อีกครั้ง',
  'self_order_table_unavailable':
      'ไม่พบโต๊ะนี้ หรือโต๊ะนี้ปิดใช้งานอยู่ กรุณาเรียกพนักงาน',
  'self_order_menu_empty': 'ยังไม่มีเมนูให้สั่งในหมวดนี้',
  'self_order_submit_success': 'ส่งออเดอร์เข้าครัวเรียบร้อยแล้ว',
  'self_order_current_order_title': 'ออเดอร์ของคุณ',
  'self_order_cart_title': 'ตะกร้าของคุณ',
  'self_order_cart_footnote':
      'ยอดนี้ยังไม่รวมค่าบริการและภาษี ระบบจะคำนวณให้ครบหลังกดส่งเข้าครัว',
  'self_order_send_to_kitchen': 'ส่งเข้าครัว',
  'self_order_view_cart_button': 'ตะกร้า (@count) · @total',
};

const Map<String, String> selfOrderTranslationsEn = {
  'self_order_title': 'Order food',
  'self_order_loading': 'Loading the menu...',
  'self_order_invalid_link':
      'Invalid link — please scan the QR code on your table again',
  'self_order_table_unavailable':
      'Table not found, or this table is deactivated. Please call a staff member.',
  'self_order_menu_empty': 'No items in this category yet',
  'self_order_submit_success': 'Your order has been sent to the kitchen',
  'self_order_current_order_title': 'Your order',
  'self_order_cart_title': 'Your cart',
  'self_order_cart_footnote':
      "This total doesn't include service charge and VAT yet — those are added once you send it to the kitchen",
  'self_order_send_to_kitchen': 'Send to kitchen',
  'self_order_view_cart_button': 'Cart (@count) · @total',
};
