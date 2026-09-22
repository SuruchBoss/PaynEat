/// คำแปลของฟีเจอร์ลูกค้า/แต้มสะสม (ticket 09 — customer & loyalty)
const Map<String, String> customerTranslationsTh = {
  // ข้อความ error จาก demo store (ฝั่งจำลอง backend) — ใช้ข้อความเดียวกับ backend จริง
  'customer_error_not_found': 'ไม่พบลูกค้ารายนี้',
  'customer_error_phone_taken': 'เบอร์โทรนี้มีลูกค้าอื่นใช้อยู่แล้ว',

  // กล่องค้นหา/เพิ่มลูกค้า (ใช้ตอนรับออเดอร์)
  'customer_picker_title': 'ผูกลูกค้ากับออเดอร์',
  'customer_picker_search_hint': 'ค้นหาจากชื่อหรือเบอร์โทร',
  'customer_picker_empty': 'ไม่พบลูกค้าที่ตรงกับคำค้นหา',
  'customer_picker_points_badge': '@points แต้ม',
  'customer_picker_add_new_button': 'เพิ่มลูกค้าใหม่',
  'customer_picker_clear_button': 'เอาลูกค้าออก',
  'customer_picker_name_label': 'ชื่อลูกค้า',
  'customer_picker_phone_label': 'เบอร์โทร',
  'customer_picker_email_label': 'อีเมล (ถ้ามี)',
  'customer_picker_create_button': 'บันทึกและเลือก',
  'customer_picker_name_phone_required': 'กรุณากรอกชื่อและเบอร์โทร',

  // หน้ารายชื่อลูกค้า (admin/manager)
  'customer_list_search_hint': 'ค้นหาจากชื่อหรือเบอร์โทร',
  'customer_list_empty': 'ยังไม่มีลูกค้าในระบบ',
  'customer_list_points_badge': '@points แต้ม',

  // หน้ารายละเอียดลูกค้า (ประวัติการซื้อ/แต้มสะสม)
  'customer_detail_title': 'ประวัติลูกค้า',
  'customer_detail_not_found': 'ไม่พบลูกค้ารายนี้',
  'customer_detail_points_label': 'แต้มสะสมคงเหลือ',
  'customer_detail_history_title': 'ประวัติการซื้อ',
  'customer_detail_history_empty': 'ยังไม่มีประวัติการซื้อ',
  'customer_detail_points_earned': 'ได้รับ @points แต้ม',
};

const Map<String, String> customerTranslationsEn = {
  'customer_error_not_found': 'Customer not found',
  'customer_error_phone_taken':
      'This phone number is already used by another customer',

  'customer_picker_title': 'Link customer to order',
  'customer_picker_search_hint': 'Search by name or phone number',
  'customer_picker_empty': 'No customers match your search',
  'customer_picker_points_badge': '@points pts',
  'customer_picker_add_new_button': 'Add new customer',
  'customer_picker_clear_button': 'Remove customer',
  'customer_picker_name_label': 'Customer name',
  'customer_picker_phone_label': 'Phone number',
  'customer_picker_email_label': 'Email (optional)',
  'customer_picker_create_button': 'Save and select',
  'customer_picker_name_phone_required': 'Please enter a name and phone number',

  'customer_list_search_hint': 'Search by name or phone number',
  'customer_list_empty': 'No customers yet',
  'customer_list_points_badge': '@points pts',

  'customer_detail_title': 'Customer history',
  'customer_detail_not_found': 'Customer not found',
  'customer_detail_points_label': 'Points balance',
  'customer_detail_history_title': 'Purchase history',
  'customer_detail_history_empty': 'No purchase history yet',
  'customer_detail_points_earned': 'Earned @points points',
};

const Map<String, String> customerTranslationsKo = {
  'customer_error_not_found': '고객을 찾을 수 없습니다',
  'customer_error_phone_taken': '이 전화번호는 다른 고객이 이미 사용 중입니다',
  'customer_picker_title': '주문에 고객 연결',
  'customer_picker_search_hint': '이름 또는 전화번호로 검색',
  'customer_picker_empty': '검색 결과가 없습니다',
  'customer_picker_points_badge': '@points P',
  'customer_picker_add_new_button': '신규 고객 등록',
  'customer_picker_clear_button': '고객 연결 해제',
  'customer_picker_name_label': '고객 이름',
  'customer_picker_phone_label': '전화번호',
  'customer_picker_email_label': '이메일 (선택)',
  'customer_picker_create_button': '저장 후 선택',
  'customer_picker_name_phone_required': '이름과 전화번호를 입력해 주세요',
  'customer_list_search_hint': '이름 또는 전화번호로 검색',
  'customer_list_empty': '등록된 고객이 없습니다',
  'customer_list_points_badge': '@points P',
  'customer_detail_title': '고객 내역',
  'customer_detail_not_found': '고객을 찾을 수 없습니다',
  'customer_detail_points_label': '적립금 잔액',
  'customer_detail_history_title': '구매 내역',
  'customer_detail_history_empty': '아직 구매 내역이 없습니다',
  'customer_detail_points_earned': '@points P 적립',
};
