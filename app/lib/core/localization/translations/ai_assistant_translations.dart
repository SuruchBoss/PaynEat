/// คำแปลของฟีเจอร์ผู้ช่วย AI ถามตอบข้อมูลร้าน (ดู docs/tickets/15-ai-ask-your-data.md)
const Map<String, String> aiAssistantTranslationsTh = {
  'ai_assistant_empty_title': 'ถามอะไรเกี่ยวกับร้านก็ได้',
  'ai_assistant_empty_subtitle':
      'ตอบจากข้อมูลจริงในระบบเท่านั้น (ยอดขาย เมนู ออเดอร์ ลูกค้า) ไม่เดา ไม่แต่งตัวเลข',
  'ai_assistant_input_hint': 'พิมพ์คำถาม เช่น ยอดขายวันนี้เท่าไร',
  'ai_assistant_send_button': 'ส่งคำถาม',
  'ai_assistant_thinking': 'กำลังค้นข้อมูล...',
  'ai_assistant_remaining_today': 'เหลือ @count คำถามวันนี้',
  'ai_assistant_sources_label': 'แหล่งข้อมูล:',
  'ai_assistant_error_disabled':
      'ผู้ช่วย AI ยังไม่ได้เปิดใช้งานสำหรับระบบนี้ (ยังไม่ได้ตั้งค่า ANTHROPIC_API_KEY)',

  'ai_assistant_example_sales_today': 'ยอดขายวันนี้เท่าไร',
  'ai_assistant_example_top_items_week': 'เมนูไหนขายดีสุดอาทิตย์นี้',
  'ai_assistant_example_top_customer': 'ลูกค้าคนไหนซื้อบ่อยสุด',

  'ai_assistant_source_sales_summary': 'สรุปยอดขาย',
  'ai_assistant_source_top_items': 'เมนูขายดี',
  'ai_assistant_source_sales_by_day': 'ยอดขายรายวัน',
  'ai_assistant_source_recent_orders': 'รายการออเดอร์',
  'ai_assistant_source_top_customers': 'ลูกค้าประจำ',
  'ai_assistant_source_audit_log': 'ประวัติการทำรายการ',
};

const Map<String, String> aiAssistantTranslationsEn = {
  'ai_assistant_empty_title': 'Ask anything about the store',
  'ai_assistant_empty_subtitle':
      'Answers come only from real data in the system (sales, menu, orders, customers) — never guessed or made up.',
  'ai_assistant_input_hint': "e.g. What are today's sales?",
  'ai_assistant_send_button': 'Send',
  'ai_assistant_thinking': 'Looking up the data...',
  'ai_assistant_remaining_today': '@count questions left today',
  'ai_assistant_sources_label': 'Sources:',
  'ai_assistant_error_disabled':
      'The AI assistant is not enabled on this server (ANTHROPIC_API_KEY not set).',

  'ai_assistant_example_sales_today': "What are today's sales?",
  'ai_assistant_example_top_items_week': 'Which menu item sold best this week?',
  'ai_assistant_example_top_customer': 'Which customer orders most often?',

  'ai_assistant_source_sales_summary': 'Sales summary',
  'ai_assistant_source_top_items': 'Top-selling items',
  'ai_assistant_source_sales_by_day': 'Sales by day',
  'ai_assistant_source_recent_orders': 'Recent orders',
  'ai_assistant_source_top_customers': 'Top customers',
  'ai_assistant_source_audit_log': 'Audit log',
};

const Map<String, String> aiAssistantTranslationsKo = {
  'ai_assistant_empty_title': '매장에 대해 무엇이든 물어보세요',
  'ai_assistant_empty_subtitle':
      '답변은 시스템에 실제로 저장된 데이터(매출, 메뉴, 주문, 고객)에서만 가져옵니다. 추측하거나 지어내지 않습니다.',
  'ai_assistant_input_hint': '예: 오늘 매출이 얼마인가요?',
  'ai_assistant_send_button': '보내기',
  'ai_assistant_thinking': '데이터를 조회하는 중...',
  'ai_assistant_remaining_today': '오늘 @count회 남음',
  'ai_assistant_sources_label': '출처:',
  'ai_assistant_error_disabled':
      '이 서버에서는 AI 어시스턴트가 켜져 있지 않습니다 (ANTHROPIC_API_KEY 미설정).',
  'ai_assistant_example_sales_today': '오늘 매출이 얼마인가요?',
  'ai_assistant_example_top_items_week': '이번 주에 가장 많이 팔린 메뉴는 무엇인가요?',
  'ai_assistant_example_top_customer': '가장 자주 방문하는 고객은 누구인가요?',
  'ai_assistant_source_sales_summary': '매출 요약',
  'ai_assistant_source_top_items': '인기 메뉴',
  'ai_assistant_source_sales_by_day': '일자별 매출',
  'ai_assistant_source_recent_orders': '최근 주문',
  'ai_assistant_source_top_customers': '주요 고객',
  'ai_assistant_source_audit_log': '변경 이력',
};
