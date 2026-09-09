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
