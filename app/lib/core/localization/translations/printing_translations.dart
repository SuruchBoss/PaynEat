/// คำแปลของใบเสร็จที่พิมพ์จริงผ่านเครื่องพิมพ์ความร้อน (ESC/POS)
///
/// ป้ายที่ตรงกับใบเสร็จบนจอ (subtotal, discount, grand total ฯลฯ) ใช้คีย์ร่วมกับ
/// payment_translations.dart อยู่แล้ว ไฟล์นี้มีเฉพาะข้อความที่มีแค่ในใบเสร็จกระดาษ
const Map<String, String> printingTranslationsTh = {
  'printing_receipt_subtitle': 'ใบเสร็จรับเงิน / ใบกำกับภาษีอย่างย่อ',
  'printing_receipt_no_label': 'เลขที่: @code',
  'printing_receipt_date_label': 'วันที่: @datetime',
  'printing_receipt_target_label': 'โต๊ะ/ประเภท: @target',
  'printing_receipt_waiter_label': 'พนักงาน: @name',
  'printing_receipt_guest_count_label': 'จำนวนลูกค้า: @count ท่าน',
  'printing_refund_section_title': 'รายการคืนเงิน',
  'printing_thank_you': 'ขอบคุณที่ใช้บริการ',
  'printing_test_page_title': 'ทดสอบเครื่องพิมพ์ PaynEat POS',
  'printing_test_page_success_message': 'พิมพ์ได้ถูกต้อง แปลว่าตั้งค่าสำเร็จ',
  // ทดสอบว่าเครื่องพิมพ์แสดงอักษรไทยได้ถูกต้อง — คงข้อความเดิมไว้ทั้งสองภาษา
  // เพราะจุดประสงค์คือทดสอบการเข้ารหัสอักษรไทย ไม่ใช่เนื้อหาที่ต้องแปล
  'printing_test_thai_charset': 'ทดสอบอักษรไทย: ก-ฮ ๐-๙ ฿100.00',
};

const Map<String, String> printingTranslationsEn = {
  'printing_receipt_subtitle': 'Receipt / Abbreviated Tax Invoice',
  'printing_receipt_no_label': 'No.: @code',
  'printing_receipt_date_label': 'Date: @datetime',
  'printing_receipt_target_label': 'Table/Type: @target',
  'printing_receipt_waiter_label': 'Server: @name',
  'printing_receipt_guest_count_label': 'Guests: @count',
  'printing_refund_section_title': 'Refunds',
  'printing_thank_you': 'Thank you for your visit',
  'printing_test_page_title': 'PaynEat POS Printer Test',
  'printing_test_page_success_message':
      'If this prints correctly, setup was successful',
  'printing_test_thai_charset': 'ทดสอบอักษรไทย: ก-ฮ ๐-๙ ฿100.00',
};

const Map<String, String> printingTranslationsKo = {
  'printing_receipt_subtitle': '영수증 / 간이 세금계산서',
  'printing_receipt_no_label': '번호: @code',
  'printing_receipt_date_label': '일시: @datetime',
  'printing_receipt_target_label': '테이블/유형: @target',
  'printing_receipt_waiter_label': '담당: @name',
  'printing_receipt_guest_count_label': '인원: @count명',
  'printing_refund_section_title': '환불',
  'printing_thank_you': '이용해 주셔서 감사합니다',
  'printing_test_page_title': 'PaynEat POS 프린터 테스트',
  'printing_test_page_success_message': '이 내용이 정상 출력되면 설정이 완료된 것입니다',
  'printing_test_thai_charset': 'ทดสอบอักษรไทย: ก-ฮ ๐-๙ ฿100.00',
};
