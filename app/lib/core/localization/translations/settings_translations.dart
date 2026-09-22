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

  'settings_promptpay_title': 'พร้อมเพย์',
  'settings_promptpay_subtitle':
      'ต้องตั้งค่าก่อน ช่องทางจ่าย "QR" จึงจะแสดง QR พร้อมเพย์จริงให้ลูกค้าสแกนได้',
  'settings_promptpay_id_label': 'เลขพร้อมเพย์',
  'settings_promptpay_id_hint': 'เบอร์โทร/เลขบัตรประชาชน/เลขผู้เสียภาษี',
  'settings_promptpay_not_configured_error':
      'ร้านยังไม่ได้ตั้งค่าเลขพร้อมเพย์ (ตั้งได้ที่หน้าตั้งค่าระบบ)',

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
  'settings_language_ko': '한국어',
  'settings_contrast_title': 'ความคมชัดของหน้าจอ',
  'settings_contrast_subtitle':
      'เลือก "สูง" ถ้าจอโดนแดด อยู่ในครัว หรือมองเห็นตัวหนังสือไม่ชัด',
  'settings_contrast_standard': 'ปกติ',
  'settings_contrast_high': 'สูง',

  'settings_loyalty_title': 'แต้มสะสม',
  'settings_loyalty_subtitle': 'อัตราแลกแต้ม มีผลกับทุกออเดอร์หลังจากนี้',
  'settings_points_earn_rate_label': 'จ่ายกี่บาทได้ 1 แต้ม',
  'settings_points_redeem_value_label': 'มูลค่า 1 แต้มตอนใช้แลกส่วนลด',
  'settings_points_baht_per_point': 'บาท',
  'settings_points_earn_rate_error': 'อัตราสะสมแต้มต้องมากกว่า 0',
  'settings_points_redeem_value_error': 'มูลค่าแต้มต้องไม่ติดลบ',
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

  'settings_promptpay_title': 'PromptPay',
  'settings_promptpay_subtitle':
      'Set this before the "QR" payment method can show a real scannable PromptPay QR code',
  'settings_promptpay_id_label': 'PromptPay ID',
  'settings_promptpay_id_hint': 'Phone number / National ID / Tax ID',
  'settings_promptpay_not_configured_error':
      'The store has not set a PromptPay ID yet (set it under Settings)',

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
  'settings_language_ko': '한국어',
  'settings_contrast_title': 'Screen contrast',
  'settings_contrast_subtitle':
      'Pick "High" for screens in sunlight or in the kitchen, or if text is hard to read',
  'settings_contrast_standard': 'Standard',
  'settings_contrast_high': 'High',

  'settings_loyalty_title': 'Loyalty points',
  'settings_loyalty_subtitle':
      'Exchange rate — applies to every order after this',
  'settings_points_earn_rate_label': 'Baht spent per 1 point earned',
  'settings_points_redeem_value_label': 'Value of 1 point when redeemed',
  'settings_points_baht_per_point': 'baht',
  'settings_points_earn_rate_error': 'The earn rate must be greater than 0',
  'settings_points_redeem_value_error': 'The redeem value cannot be negative',
};

const Map<String, String> settingsTranslationsKo = {
  'settings_store_info_title': '매장 정보',
  'settings_store_info_subtitle': '매장명은 영수증에 표시됩니다',
  'settings_store_name_label': '매장명',
  'settings_bill_calc_title': '금액 계산',
  'settings_bill_calc_subtitle': '이후 새로 여는 주문부터 적용됩니다',
  'settings_vat_label': '부가가치세',
  'settings_service_charge_label': '서비스 차지',
  'settings_vat_included_title': '메뉴 가격에 부가세가 포함되어 있음',
  'settings_vat_included_subtitle': '켜면 가격에 더하지 않고 가격에서 부가세를 분리해 계산합니다',
  'settings_save_button': '설정 저장',
  'settings_vat_range_error': '부가가치세는 0~100 사이여야 합니다',
  'settings_service_charge_range_error': '서비스 차지는 0~100 사이여야 합니다',
  'settings_saved_success': '설정을 저장했습니다',
  'settings_tax_invoice_title': '세금계산서 정보',
  'settings_tax_invoice_subtitle': '세금계산서를 발행하려면 매장 사업자번호와 주소를 먼저 입력해야 합니다',
  'settings_store_tax_id_label': '사업자번호',
  'settings_store_tax_id_hint': '13자리',
  'settings_store_address_label': '매장 주소',
  'settings_store_branch_label': '지점',
  'settings_store_branch_hint': '예: 본점, 001지점',
  'settings_promptpay_title': '프롬프트페이',
  'settings_promptpay_subtitle': '입력해야 "QR" 결제 수단에서 실제로 스캔되는 프롬프트페이 QR이 표시됩니다',
  'settings_promptpay_id_label': '프롬프트페이 ID',
  'settings_promptpay_id_hint': '휴대폰 번호 / 주민등록번호 / 사업자번호',
  'settings_promptpay_not_configured_error':
      '매장에 프롬프트페이 ID가 아직 등록되지 않았습니다 (설정에서 입력하세요)',
  'settings_printer_title': '영수증 프린터',
  'settings_printer_subtitle':
      '같은 LAN/Wi-Fi 네트워크의 영수증 프린터로 출력합니다 (웹에서는 아직 지원되지 않습니다)',
  'settings_printer_enable_title': '이 프린터 사용',
  'settings_printer_enable_subtitle': '끄면 기존처럼 화면으로 영수증을 표시합니다',
  'settings_printer_ip_label': '프린터 IP',
  'settings_printer_ip_hint': '예: 192.168.1.50',
  'settings_printer_port_label': '포트',
  'settings_printer_paper_58mm': '58 mm',
  'settings_printer_paper_80mm': '80 mm',
  'settings_printer_test_button': '테스트 출력',
  'settings_printer_ip_required': '프린터 IP를 입력해 주세요',
  'settings_printer_port_invalid': '올바르지 않은 포트입니다',
  'settings_printer_saved_success': '프린터 설정을 저장했습니다',
  'settings_printer_test_success': '테스트 출력을 전송했습니다',
  'settings_printer_web_not_supported':
      '웹에서는 영수증 프린터 출력이 아직 지원되지 않습니다. 화면 영수증을 사용해 주세요.',
  'settings_printer_not_configured':
      '프린터가 아직 설정되지 않았습니다. 설정 > 영수증 프린터에서 등록해 주세요.',
  'settings_printer_print_failed': '출력 실패: 프린터에 연결할 수 없습니다 (@error)',
  'settings_printer_platform_not_supported': '이 플랫폼에서는 프린터 연결이 지원되지 않습니다',
  'settings_about_title': '정보',
  'settings_about_app_label': '애플리케이션',
  'settings_about_version_label': '버전',
  'settings_about_server_label': '서버',
  'settings_language_title': '언어',
  'settings_language_subtitle': '선택하면 앱 언어가 바로 바뀝니다',
  'settings_language_th': 'ไทย',
  'settings_language_en': 'English',
  'settings_language_ko': '한국어',
  'settings_contrast_title': '화면 대비',
  'settings_contrast_subtitle':
      '햇빛이 드는 자리나 주방에 두는 화면, 글씨가 잘 안 보일 때는 "높음"을 선택하세요',
  'settings_contrast_standard': '표준',
  'settings_contrast_high': '높음',
  'settings_loyalty_title': '적립금',
  'settings_loyalty_subtitle': '적립·사용 기준 — 이후 주문부터 적용됩니다',
  'settings_points_earn_rate_label': '1포인트 적립에 필요한 결제 금액',
  'settings_points_redeem_value_label': '1포인트 사용 시 금액',
  'settings_points_baht_per_point': '바트',
  'settings_points_earn_rate_error': '적립 기준 금액은 0보다 커야 합니다',
  'settings_points_redeem_value_error': '사용 금액은 음수일 수 없습니다',
};
