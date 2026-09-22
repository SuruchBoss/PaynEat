/// คำแปลของฟีเจอร์ tax_invoice (ใบกำกับภาษี — ดู docs/tickets/07-tax-invoice.md)
const Map<String, String> taxInvoiceTranslationsTh = {
  // Receipt page section
  'tax_invoice_request_button': 'ขอใบกำกับภาษี',
  'tax_invoice_tap_to_view_hint': 'แตะเพื่อดูใบกำกับภาษี',

  // Request dialog
  'tax_invoice_request_title': 'ขอใบกำกับภาษี',
  'tax_invoice_type_abbreviated': 'อย่างย่อ',
  'tax_invoice_type_full': 'เต็มรูป',
  'tax_invoice_customer_name_label': 'ชื่อลูกค้า/บริษัท *',
  'tax_invoice_customer_address_label': 'ที่อยู่ลูกค้า *',
  'tax_invoice_customer_tax_id_label': 'เลขผู้เสียภาษีลูกค้า',
  'tax_invoice_customer_tax_id_hint': 'ไม่บังคับ',
  'tax_invoice_full_requires_customer_error':
      'ใบกำกับภาษีเต็มรูปต้องระบุชื่อและที่อยู่ลูกค้า',
  'tax_invoice_request_submit_button': 'ออกใบกำกับภาษี',
  'tax_invoice_issued_success': 'ออกใบกำกับภาษีแล้ว',

  // Document dialog
  'tax_invoice_document_title_full': 'ใบกำกับภาษี',
  'tax_invoice_document_title_abbreviated': 'ใบกำกับภาษีอย่างย่อ',
  'tax_invoice_running_number_label': 'เลขที่',
  'tax_invoice_issued_at_label': 'วันที่ออก',
  'tax_invoice_order_code_label': 'เลขที่ออเดอร์',
  'tax_invoice_store_section_title': 'ผู้ขาย',
  'tax_invoice_customer_section_title': 'ผู้ซื้อ',
  'tax_invoice_tax_id_value': 'เลขผู้เสียภาษี: @taxId',
  'tax_invoice_subtotal_label': 'มูลค่าสินค้า/บริการ',
  'tax_invoice_vat_label': 'ภาษีมูลค่าเพิ่ม',
  'tax_invoice_total_label': 'รวมทั้งสิ้น',
  'tax_invoice_total_vat_included_label':
      'รวมทั้งสิ้น (รวมภาษีมูลค่าเพิ่มแล้ว)',
  'tax_invoice_issued_by_label': 'ออกโดย @name',
  'tax_invoice_voided_badge': 'ยกเลิกแล้ว',
  'tax_invoice_void_button': 'ยกเลิกใบกำกับภาษี',
  'tax_invoice_void_confirm_title': 'ยกเลิกใบกำกับภาษี',
  'tax_invoice_void_reason_label': 'เหตุผลที่ยกเลิก',
  'tax_invoice_void_confirm_button': 'ยืนยันยกเลิก',
  'tax_invoice_voided_success': 'ยกเลิกใบกำกับภาษีแล้ว',

  // Demo store errors
  'tax_invoice_error_not_found': 'ยังไม่มีใบกำกับภาษีสำหรับออเดอร์นี้',
  'tax_invoice_error_not_paid':
      'ออกใบกำกับภาษีได้ก็ต่อเมื่อออเดอร์นี้ชำระเงินครบแล้ว',
  'tax_invoice_error_already_issued':
      'ออเดอร์นี้มีใบกำกับภาษีที่ยังไม่ถูกยกเลิกอยู่แล้ว',
  'tax_invoice_error_store_not_configured':
      'ร้านยังไม่ได้ตั้งค่าเลขประจำตัวผู้เสียภาษี/ที่อยู่ร้าน กรุณาตั้งค่าในหน้า Settings ก่อน',
  'tax_invoice_error_full_requires_customer':
      'ใบกำกับภาษีเต็มรูปต้องระบุชื่อและที่อยู่ลูกค้า',
};

const Map<String, String> taxInvoiceTranslationsEn = {
  // Receipt page section
  'tax_invoice_request_button': 'Request tax invoice',
  'tax_invoice_tap_to_view_hint': 'Tap to view the tax invoice',

  // Request dialog
  'tax_invoice_request_title': 'Request a tax invoice',
  'tax_invoice_type_abbreviated': 'Abbreviated',
  'tax_invoice_type_full': 'Full',
  'tax_invoice_customer_name_label': 'Customer/company name *',
  'tax_invoice_customer_address_label': 'Customer address *',
  'tax_invoice_customer_tax_id_label': "Customer's tax ID",
  'tax_invoice_customer_tax_id_hint': 'Optional',
  'tax_invoice_full_requires_customer_error':
      'A full tax invoice requires the customer name and address',
  'tax_invoice_request_submit_button': 'Issue tax invoice',
  'tax_invoice_issued_success': 'Tax invoice issued',

  // Document dialog
  'tax_invoice_document_title_full': 'Tax Invoice',
  'tax_invoice_document_title_abbreviated': 'Abbreviated Tax Invoice',
  'tax_invoice_running_number_label': 'No.',
  'tax_invoice_issued_at_label': 'Issued at',
  'tax_invoice_order_code_label': 'Order code',
  'tax_invoice_store_section_title': 'Seller',
  'tax_invoice_customer_section_title': 'Buyer',
  'tax_invoice_tax_id_value': 'Tax ID: @taxId',
  'tax_invoice_subtotal_label': 'Goods/services value',
  'tax_invoice_vat_label': 'VAT',
  'tax_invoice_total_label': 'Total',
  'tax_invoice_total_vat_included_label': 'Total (VAT included)',
  'tax_invoice_issued_by_label': 'Issued by @name',
  'tax_invoice_voided_badge': 'Voided',
  'tax_invoice_void_button': 'Void this invoice',
  'tax_invoice_void_confirm_title': 'Void tax invoice',
  'tax_invoice_void_reason_label': 'Reason for voiding',
  'tax_invoice_void_confirm_button': 'Confirm void',
  'tax_invoice_voided_success': 'Tax invoice voided',

  // Demo store errors
  'tax_invoice_error_not_found': 'This order has no tax invoice yet',
  'tax_invoice_error_not_paid':
      'A tax invoice can only be issued once this order is fully paid',
  'tax_invoice_error_already_issued':
      'This order already has an active tax invoice',
  'tax_invoice_error_store_not_configured':
      'Set the store tax ID/address in Settings before issuing a tax invoice',
  'tax_invoice_error_full_requires_customer':
      'A full tax invoice requires the customer name and address',
};

const Map<String, String> taxInvoiceTranslationsKo = {
  'tax_invoice_request_button': '세금계산서 요청',
  'tax_invoice_tap_to_view_hint': '눌러서 세금계산서 보기',
  'tax_invoice_request_title': '세금계산서 요청',
  'tax_invoice_type_abbreviated': '간이',
  'tax_invoice_type_full': '일반',
  'tax_invoice_customer_name_label': '고객/회사명 *',
  'tax_invoice_customer_address_label': '고객 주소 *',
  'tax_invoice_customer_tax_id_label': '고객 사업자번호',
  'tax_invoice_customer_tax_id_hint': '선택 입력',
  'tax_invoice_full_requires_customer_error': '일반 세금계산서는 고객명과 주소가 필요합니다',
  'tax_invoice_request_submit_button': '세금계산서 발행',
  'tax_invoice_issued_success': '세금계산서를 발행했습니다',
  'tax_invoice_document_title_full': '세금계산서',
  'tax_invoice_document_title_abbreviated': '간이 세금계산서',
  'tax_invoice_running_number_label': '번호',
  'tax_invoice_issued_at_label': '발행 일시',
  'tax_invoice_order_code_label': '주문 번호',
  'tax_invoice_store_section_title': '공급자',
  'tax_invoice_customer_section_title': '공급받는 자',
  'tax_invoice_tax_id_value': '사업자번호: @taxId',
  'tax_invoice_subtotal_label': '공급가액',
  'tax_invoice_vat_label': '부가가치세',
  'tax_invoice_total_label': '합계',
  'tax_invoice_total_vat_included_label': '합계 (부가세 포함)',
  'tax_invoice_issued_by_label': '발행자 @name',
  'tax_invoice_voided_badge': '취소됨',
  'tax_invoice_void_button': '이 세금계산서 취소',
  'tax_invoice_void_confirm_title': '세금계산서 취소',
  'tax_invoice_void_reason_label': '취소 사유',
  'tax_invoice_void_confirm_button': '취소 확정',
  'tax_invoice_voided_success': '세금계산서를 취소했습니다',
  'tax_invoice_error_not_found': '이 주문에는 아직 세금계산서가 없습니다',
  'tax_invoice_error_not_paid': '주문이 전액 결제된 뒤에만 세금계산서를 발행할 수 있습니다',
  'tax_invoice_error_already_issued': '이 주문에는 이미 유효한 세금계산서가 있습니다',
  'tax_invoice_error_store_not_configured':
      '세금계산서를 발행하기 전에 설정에서 매장 사업자번호와 주소를 입력해 주세요',
  'tax_invoice_error_full_requires_customer': '일반 세금계산서는 고객명과 주소가 필요합니다',
};
