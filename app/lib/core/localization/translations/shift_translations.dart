/// คำแปลของฟีเจอร์ shift — เปิด/ปิดกะแคชเชียร์ และกระทบยอดเงินสด
const Map<String, String> shiftTranslationsTh = {
  'shift_page_title': 'เปิด / ปิดกะ',

  'shift_open_new_shift': 'เปิดกะใหม่',
  'shift_open_new_subtitle': 'กรอกเงินสดตั้งต้นในลิ้นชักก่อนเริ่มรับชำระเงิน',
  'shift_starting_cash_label': 'เงินตั้งต้น',
  'shift_open_button': 'เปิดกะ',

  'shift_currently_open_title': 'กะกำลังเปิดอยู่',
  'shift_opened_by_label': 'เปิดโดย',
  'shift_opened_at_label': 'เวลาเปิดกะ',

  'shift_close_button': 'ปิดกะ',
  'shift_close_subtitle':
      'นับเงินสดในลิ้นชักจริงแล้วกรอกยอด ระบบจะคำนวณส่วนต่างให้อัตโนมัติ',
  'shift_counted_cash_label': 'ยอดเงินสดที่นับได้จริง',
  'shift_note_label': 'หมายเหตุ (ถ้ามี)',

  'shift_close_summary_title': 'สรุปผลปิดกะ',
  'shift_expected_cash_label': 'ยอดที่ระบบคาดไว้',
  'shift_variance_balanced': 'ยอดตรงพอดี',
  'shift_variance_short': 'เงินขาด',
  'shift_variance_over': 'เงินเกิน',

  'shift_history_title': 'ประวัติกะย้อนหลัง',
  'shift_history_open_subtitle': 'เปิดอยู่ · @name',
  'shift_variance_label': 'ปิดแล้ว · ส่วนต่าง @amount',

  'shift_invalid_opening_cash': 'กรุณากรอกเงินตั้งต้นให้ถูกต้อง',
  'shift_open_success': 'เปิดกะเรียบร้อย',
  'shift_invalid_counted_cash': 'กรุณากรอกยอดเงินสดที่นับได้ให้ถูกต้อง',
  'shift_close_confirm_title': 'ยืนยันปิดกะ',
  'shift_close_confirm_message':
      'ปิดกะนี้แล้วจะแก้ไขไม่ได้ ต้องการดำเนินการต่อหรือไม่?',
  'shift_close_success': 'ปิดกะเรียบร้อย',

  'shift_error_already_open': 'มีกะที่เปิดอยู่แล้ว ต้องปิดกะเดิมก่อนเปิดกะใหม่',
  'shift_error_not_found': 'ไม่พบกะนี้',
  'shift_error_already_closed': 'กะนี้ปิดไปแล้ว',
};

const Map<String, String> shiftTranslationsEn = {
  'shift_page_title': 'Open / Close Shift',

  'shift_open_new_shift': 'Open new shift',
  'shift_open_new_subtitle':
      'Enter the starting cash in the drawer before you start accepting payments',
  'shift_starting_cash_label': 'Starting cash',
  'shift_open_button': 'Open shift',

  'shift_currently_open_title': 'Shift currently open',
  'shift_opened_by_label': 'Opened by',
  'shift_opened_at_label': 'Opened at',

  'shift_close_button': 'Close shift',
  'shift_close_subtitle':
      'Count the actual cash in the drawer and enter the amount — the system will calculate the variance automatically',
  'shift_counted_cash_label': 'Counted cash',
  'shift_note_label': 'Note (optional)',

  'shift_close_summary_title': 'Shift close summary',
  'shift_expected_cash_label': 'Expected cash',
  'shift_variance_balanced': 'Balanced',
  'shift_variance_short': 'Cash short',
  'shift_variance_over': 'Cash over',

  'shift_history_title': 'Shift history',
  'shift_history_open_subtitle': 'Open · @name',
  'shift_variance_label': 'Closed · Variance @amount',

  'shift_invalid_opening_cash': 'Please enter a valid starting cash amount',
  'shift_open_success': 'Shift opened successfully',
  'shift_invalid_counted_cash': 'Please enter a valid counted cash amount',
  'shift_close_confirm_title': 'Confirm close shift',
  'shift_close_confirm_message':
      'Once closed, this shift cannot be edited. Do you want to continue?',
  'shift_close_success': 'Shift closed successfully',

  'shift_error_already_open':
      'A shift is already open. Close it before opening a new one.',
  'shift_error_not_found': 'Shift not found',
  'shift_error_already_closed': 'This shift is already closed',
};
