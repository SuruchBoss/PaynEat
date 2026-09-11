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
