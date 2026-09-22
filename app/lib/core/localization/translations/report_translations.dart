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

  // export CSV (ดู docs/tickets/12-report-export.md)
  'report_export_csv_button': 'ส่งออก CSV',
  'report_export_summary_option': 'สรุปยอดขาย',
  'report_export_top_items_option': 'เมนูขายดี',
  'report_export_sales_by_day_option': 'ยอดขายรายวัน',
  'report_export_unsupported_platform':
      'ส่งออก CSV รองรับเฉพาะบนเว็บ (หน้านี้อยู่ในโซนผู้ดูแลระบบซึ่งเป็นเว็บเท่านั้น)',
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

  // CSV export (see docs/tickets/12-report-export.md)
  'report_export_csv_button': 'Export CSV',
  'report_export_summary_option': 'Sales summary',
  'report_export_top_items_option': 'Top items',
  'report_export_sales_by_day_option': 'Sales by day',
  'report_export_unsupported_platform':
      'CSV export is only supported on the web (this page is admin/web-only)',
};

const Map<String, String> reportTranslationsKo = {
  'report_uncategorized': '미분류',
  'report_range_today': '오늘',
  'report_range_last_7_days': '최근 7일',
  'report_range_this_month': '이번 달',
  'report_range_custom': '기간 지정',
  'report_net_sales_label': '순매출',
  'report_today_sales_label': '오늘 매출',
  'report_order_count_label': '주문 건수',
  'report_subtotal_label': '세전 합계',
  'report_average_per_order_label': '건당 평균',
  'report_discount_given_label': '할인 금액',
  'report_guest_count_caption': '방문 @count명',
  'report_service_charge_caption': '서비스 차지 @amount',
  'report_average_per_guest_caption': '객단가 @amount',
  'report_today_sales_caption': '부가가치세와 서비스 차지 포함',
  'report_vat_caption': '부가가치세 @amount',
  'report_daily_sales_title': '일자별 매출',
  'report_top_items_title': '인기 메뉴 TOP 10',
  'report_sales_by_category_title': '카테고리별 매출',
  'report_hourly_sales_title': '시간대별 매출',
  'report_hourly_sales_subtitle': '어느 시간대에 손님이 가장 많은지 확인하세요',
  'report_top_items_today_title': '오늘의 인기 메뉴',
  'report_payment_methods_title': '결제 수단',
  'report_no_data_for_range': '선택한 기간에 데이터가 없습니다',
  'report_no_sales_today': '오늘은 아직 매출이 없습니다',
  'report_no_payments_yet': '아직 결제 내역이 없습니다',
  'report_quantity_plates': '@count개',
  'report_bill_count': '@count건',
  'report_open_orders_label': '진행 중 주문',
  'report_occupied_tables_label': '사용 중 테이블',
  'report_pending_kitchen_label': '주방 대기',
  'report_dashboard_loading': '전체 현황을 불러오는 중...',
  'report_export_csv_button': 'CSV 내보내기',
  'report_export_summary_option': '매출 요약',
  'report_export_top_items_option': '인기 메뉴',
  'report_export_sales_by_day_option': '일자별 매출',
  'report_export_unsupported_platform':
      'CSV 내보내기는 웹에서만 지원됩니다 (이 화면은 관리자 웹 전용입니다)',
};
