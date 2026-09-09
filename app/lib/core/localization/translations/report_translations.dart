/// คำแปลของฟีเจอร์ report
const Map<String, String> reportTranslationsTh = {
  'report_uncategorized': 'ไม่ระบุหมวดหมู่',

  // ช่วงเวลาที่เลือกดูรายงาน
  'report_range_today': 'วันนี้',
  'report_range_last_7_days': '7 วันล่าสุด',
  'report_range_this_month': 'เดือนนี้',
  'report_range_custom': 'กำหนดเอง',

  // การ์ดตัวเลขสรุป
  'report_net_sales_label': 'ยอดขายสุทธิ',
  'report_today_sales_label': 'ยอดขายวันนี้',
  'report_order_count_label': 'จำนวนบิล',
  'report_subtotal_label': 'ยอดอาหารก่อนภาษี',
  'report_average_per_order_label': 'เฉลี่ยต่อบิล',
  'report_discount_given_label': 'ส่วนลดที่ให้ไป',

  // คำบรรยายใต้ตัวเลข (มีค่าแทรก)
  'report_guest_count_caption': 'ลูกค้า @count ท่าน',
  'report_service_charge_caption': 'ค่าบริการ @amount',
  'report_average_per_guest_caption': 'ต่อหัว @amount',
  'report_today_sales_caption': 'รวม VAT และค่าบริการ',
  'report_vat_caption': 'VAT @amount',

  // หัวข้อการ์ด/ส่วนต่างๆ
  'report_daily_sales_title': 'ยอดขายรายวัน',
  'report_top_items_title': 'เมนูขายดี 10 อันดับ',
  'report_sales_by_category_title': 'ยอดขายแยกตามหมวดหมู่',
  'report_hourly_sales_title': 'ยอดขายรายชั่วโมง',
  'report_hourly_sales_subtitle': 'ดูว่าช่วงไหนลูกค้าเยอะที่สุดของวัน',
  'report_top_items_today_title': 'เมนูขายดีวันนี้',
  'report_payment_methods_title': 'ช่องทางชำระเงิน',

  // ข้อความเมื่อไม่มีข้อมูล
  'report_no_data_for_range': 'ไม่มีข้อมูลในช่วงที่เลือก',
  'report_no_sales_today': 'ยังไม่มียอดขายวันนี้',
  'report_no_payments_yet': 'ยังไม่มีรายการชำระเงิน',

  // ตัวนับ (มีค่าแทรก)
  'report_quantity_plates': '@count จาน',
  'report_bill_count': '@count บิล',

  // แถบสถานะสด
  'report_open_orders_label': 'ออเดอร์ที่เปิดอยู่',
  'report_occupied_tables_label': 'โต๊ะที่ใช้งาน',
  'report_pending_kitchen_label': 'รอครัวทำ',

  'report_dashboard_loading': 'กำลังโหลดข้อมูลภาพรวม...',
};

const Map<String, String> reportTranslationsEn = {
  'report_uncategorized': 'Uncategorized',

  // Date range selector
  'report_range_today': 'Today',
  'report_range_last_7_days': 'Last 7 days',
  'report_range_this_month': 'This month',
  'report_range_custom': 'Custom',

  // Stat cards
  'report_net_sales_label': 'Net sales',
  'report_today_sales_label': "Today's sales",
  'report_order_count_label': 'Order count',
  'report_subtotal_label': 'Subtotal before tax',
  'report_average_per_order_label': 'Average per order',
  'report_discount_given_label': 'Discounts given',

  // Captions under stat values (with interpolation)
  'report_guest_count_caption': '@count guests',
  'report_service_charge_caption': 'Service charge @amount',
  'report_average_per_guest_caption': 'Per guest @amount',
  'report_today_sales_caption': 'Includes VAT and service charge',
  'report_vat_caption': 'VAT @amount',

  // Section headers
  'report_daily_sales_title': 'Daily sales',
  'report_top_items_title': 'Top 10 best sellers',
  'report_sales_by_category_title': 'Sales by category',
  'report_hourly_sales_title': 'Hourly sales',
  'report_hourly_sales_subtitle': 'See which hours bring in the most customers',
  'report_top_items_today_title': "Today's best sellers",
  'report_payment_methods_title': 'Payment methods',

  // Empty states
  'report_no_data_for_range': 'No data for the selected range',
  'report_no_sales_today': 'No sales yet today',
  'report_no_payments_yet': 'No payments yet',

  // Counters (with interpolation)
  'report_quantity_plates': '@count servings',
  'report_bill_count': '@count bills',

  // Live status bar
  'report_open_orders_label': 'Open orders',
  'report_occupied_tables_label': 'Tables in use',
  'report_pending_kitchen_label': 'Pending in kitchen',

  'report_dashboard_loading': 'Loading overview...',
};
