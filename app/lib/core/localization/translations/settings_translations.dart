/// ข้อความในหน้าตั้งค่าร้าน (SettingsPage) และตัวสลับภาษา
const Map<String, String> settingsTranslationsTh = {
  'settings_store_info_title': 'ข้อมูลร้าน',
  'settings_store_info_subtitle': 'ชื่อร้านจะแสดงบนใบเสร็จ',
  'settings_store_name_label': 'ชื่อร้าน',
  'settings_bill_calc_title': 'การคำนวณบิล',
  'settings_bill_calc_subtitle': 'มีผลกับทุกออเดอร์ที่เปิดใหม่หลังจากนี้',
  'settings_vat_label': 'VAT',
  'settings_service_charge_label': 'Service Charge',
  'settings_vat_included_title': 'ราคาเมนูรวม VAT แล้ว',
  'settings_vat_included_subtitle':
      'ถ้าเปิด ระบบจะถอด VAT ออกมาแสดงแทนการบวกเพิ่ม',
  'settings_save_button': 'บันทึกการตั้งค่า',
  'settings_vat_range_error': 'VAT ต้องอยู่ระหว่าง 0-100',
  'settings_service_charge_range_error': 'Service Charge ต้องอยู่ระหว่าง 0-100',
  'settings_saved_success': 'บันทึกการตั้งค่าแล้ว',

  'settings_tax_invoice_title': 'ข้อมูลสำหรับออกใบกำกับภาษี',
  'settings_tax_invoice_subtitle':
      'ต้องตั้งค่าเลขผู้เสียภาษีและที่อยู่ร้านก่อน จึงจะออกใบกำกับภาษีได้',
  'settings_store_tax_id_label': 'เลขประจำตัวผู้เสียภาษี',
  'settings_store_tax_id_hint': '13 หลัก',
  'settings_store_address_label': 'ที่อยู่ร้าน',
  'settings_store_branch_label': 'สาขา',
  'settings_store_branch_hint': 'เช่น สำนักงานใหญ่, สาขาที่ 001',

  'settings_printer_title': 'เครื่องพิมพ์ใบเสร็จ',
  'settings_printer_subtitle':
      'พิมพ์ผ่านเครื่องพิมพ์ความร้อนบนวง LAN/WiFi เดียวกัน (ยังไม่รองรับบนเว็บ)',
  'settings_printer_enable_title': 'เปิดใช้เครื่องพิมพ์นี้',
  'settings_printer_enable_subtitle': 'ปิดไว้ = ใช้ใบเสร็จบนจอเหมือนเดิม',
  'settings_printer_ip_label': 'IP เครื่องพิมพ์',
  'settings_printer_ip_hint': 'เช่น 192.168.1.50',
  'settings_printer_port_label': 'พอร์ต',
  'settings_printer_paper_58mm': '58 มม.',
  'settings_printer_paper_80mm': '80 มม.',
  'settings_printer_test_button': 'ทดสอบพิมพ์',
  'settings_printer_ip_required': 'กรุณากรอก IP เครื่องพิมพ์',
  'settings_printer_port_invalid': 'พอร์ตไม่ถูกต้อง',
  'settings_printer_saved_success': 'บันทึกการตั้งค่าเครื่องพิมพ์แล้ว',
  'settings_printer_test_success': 'พิมพ์ทดสอบสำเร็จ',
  'settings_printer_web_not_supported':
      'พิมพ์ผ่านเครื่องพิมพ์ความร้อนยังไม่รองรับบนเว็บ ใช้ใบเสร็จบนจอแทนได้',
  'settings_printer_not_configured':
      'ยังไม่ได้ตั้งค่าเครื่องพิมพ์ ไปที่ตั้งค่า > เครื่องพิมพ์ใบเสร็จ',
  'settings_printer_print_failed':
      'พิมพ์ใบเสร็จไม่สำเร็จ: เชื่อมต่อเครื่องพิมพ์ไม่ได้ (@error)',
  'settings_printer_platform_not_supported':
      'ไม่รองรับการเชื่อมต่อเครื่องพิมพ์บนแพลตฟอร์มนี้',

  'settings_about_title': 'เกี่ยวกับระบบ',
  'settings_about_app_label': 'แอปพลิเคชัน',
  'settings_about_version_label': 'เวอร์ชัน',
  'settings_about_server_label': 'เซิร์ฟเวอร์',

  'settings_language_title': 'ภาษา',
  'settings_language_subtitle': 'เปลี่ยนภาษาที่แสดงในแอปทันที',
  'settings_language_th': 'ไทย',
  'settings_language_en': 'English',
  'settings_contrast_title': 'ความคมชัดของหน้าจอ',
  'settings_contrast_subtitle':
      'เลือก "สูง" ถ้าจอโดนแดด อยู่ในครัว หรือมองเห็นตัวหนังสือไม่ชัด',
  'settings_contrast_standard': 'ปกติ',
  'settings_contrast_high': 'สูง',
};

const Map<String, String> settingsTranslationsEn = {
  'settings_store_info_title': 'Store Info',
  'settings_store_info_subtitle': 'The store name appears on receipts',
  'settings_store_name_label': 'Store name',
  'settings_bill_calc_title': 'Bill Calculation',
  'settings_bill_calc_subtitle': 'Applies to every order opened after this',
  'settings_vat_label': 'VAT',
  'settings_service_charge_label': 'Service Charge',
  'settings_vat_included_title': 'Menu prices already include VAT',
  'settings_vat_included_subtitle':
      'When on, VAT is extracted from the price instead of added on top',
  'settings_save_button': 'Save settings',
  'settings_vat_range_error': 'VAT must be between 0-100',
  'settings_service_charge_range_error': 'Service Charge must be between 0-100',
  'settings_saved_success': 'Settings saved',

  'settings_tax_invoice_title': 'Tax Invoice Info',
  'settings_tax_invoice_subtitle':
      'Set the store tax ID and address first — required before issuing a tax invoice',
  'settings_store_tax_id_label': 'Tax ID',
  'settings_store_tax_id_hint': '13 digits',
  'settings_store_address_label': 'Store address',
  'settings_store_branch_label': 'Branch',
  'settings_store_branch_hint': 'e.g. Head Office, Branch 001',

  'settings_printer_title': 'Receipt Printer',
  'settings_printer_subtitle':
      'Prints via a thermal printer on the same LAN/WiFi network (not supported on web yet)',
  'settings_printer_enable_title': 'Enable this printer',
  'settings_printer_enable_subtitle':
      'Off = show the receipt on screen as before',
  'settings_printer_ip_label': 'Printer IP',
  'settings_printer_ip_hint': 'e.g. 192.168.1.50',
  'settings_printer_port_label': 'Port',
  'settings_printer_paper_58mm': '58 mm',
  'settings_printer_paper_80mm': '80 mm',
  'settings_printer_test_button': 'Test print',
  'settings_printer_ip_required': 'Please enter the printer IP',
  'settings_printer_port_invalid': 'Invalid port',
  'settings_printer_saved_success': 'Printer settings saved',
  'settings_printer_test_success': 'Test print sent successfully',
  'settings_printer_web_not_supported':
      'Thermal printing is not supported on web yet. Use the on-screen receipt instead.',
  'settings_printer_not_configured':
      'The printer is not set up yet. Go to Settings > Receipt Printer.',
  'settings_printer_print_failed':
      'Print failed: could not connect to the printer (@error)',
  'settings_printer_platform_not_supported':
      'Printer connection is not supported on this platform',

  'settings_about_title': 'About',
  'settings_about_app_label': 'Application',
  'settings_about_version_label': 'Version',
  'settings_about_server_label': 'Server',

  'settings_language_title': 'Language',
  'settings_language_subtitle': 'Changes the app language immediately',
  'settings_language_th': 'ไทย',
  'settings_language_en': 'English',
  'settings_contrast_title': 'Screen contrast',
  'settings_contrast_subtitle':
      'Pick "High" for screens in sunlight or in the kitchen, or if text is hard to read',
  'settings_contrast_standard': 'Standard',
  'settings_contrast_high': 'High',
};
