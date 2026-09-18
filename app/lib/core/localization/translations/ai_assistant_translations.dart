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
