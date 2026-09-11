/// คำแปลของฟีเจอร์ payment (เก็บเงิน / ใบเสร็จ / แยกบิล / คืนเงิน)
const Map<String, String> paymentTranslationsTh = {
  // checkout_page
  'payment_checkout_title': 'เก็บเงิน / ปิดบิล',
  'payment_order_not_found': 'ไม่พบออเดอร์',
  'payment_no_shift_banner':
      'ยังไม่ได้เปิดกะ ต้องเปิดกะก่อนจึงจะรับชำระเงินได้',
  'payment_go_open_shift': 'ไปเปิดกะ',
  'payment_already_paid_section_title': 'ชำระมาแล้ว',
  'payment_remaining_due_label': 'คงเหลือต้องชำระ',
  'payment_method_section_title': 'ช่องทางชำระเงิน',
  'payment_amount_this_round_label': 'ยอดที่รับชำระรอบนี้',
  'payment_amount_this_round_helper': 'แก้ได้ถ้าลูกค้าขอจ่ายบางส่วน',
  'payment_received_label': 'รับเงินมา',
  'payment_received_helper': 'ใส่จำนวนเงินที่ลูกค้ายื่นให้ ระบบจะคิดเงินทอนให้เอง',
  'payment_exact_amount_label': 'พอดี',
  'payment_change_due_label': 'เงินทอน',
  'payment_reference_label': 'เลขอ้างอิง (ถ้ามี)',
  'payment_reference_hint': 'เช่น เลขที่สลิป / 4 ตัวท้ายบัตร',
  'payment_submit_button': 'รับชำระ @amount',

  // checkout_controller / split_bill_controller (snackbar)
  'payment_bill_closed_success': 'ปิดบิลเรียบร้อย',
  'payment_partial_paid_success': 'รับชำระแล้ว คงเหลือ @amount บาท',

  // split_bill_page
  'payment_split_bill_title': 'แยกบิลรายการอาหาร',
  'payment_order_already_paid': 'ออเดอร์นี้ชำระเงินครบแล้ว',
  'payment_split_bill_instructions':
      'แตะเลือกเมนูที่จะให้คนนี้จ่าย แล้วกดชำระ — ทำซ้ำได้จนครบทุกรายการ',
  'payment_item_paid_label': 'จ่ายแล้ว',
  'payment_item_quantity_label': '@count รายการ',
  'payment_select_items_hint': 'เลือกรายการด้านบนเพื่อดูยอดที่ต้องจ่าย',
  'payment_selected_subtotal_label': 'ยอดรายการที่เลือก',
  'payment_discount_label': 'ส่วนลด',
  'payment_service_charge_label': 'Service Charge',
  'payment_vat_label': 'VAT',
  'payment_amount_due_this_round_label': 'ยอดที่ต้องจ่ายรอบนี้',

  // receipt_page
  'payment_receipt_title': 'ใบเสร็จรับเงิน',
  'payment_print_receipt_tooltip': 'พิมพ์ใบเสร็จ',
  'payment_back_to_home_tooltip': 'กลับหน้าหลัก',
  'payment_receipt_not_found': 'ไม่พบข้อมูลใบเสร็จ',
  'payment_receipt_subtitle': 'ใบเสร็จรับเงิน / ใบกำกับภาษีอย่างย่อ',
  'payment_receipt_order_code_label': 'เลขที่',
  'payment_receipt_date_label': 'วันที่',
  'payment_receipt_table_type_label': 'โต๊ะ / ประเภท',
  'payment_receipt_staff_label': 'พนักงาน',
  'payment_receipt_guest_count_label': 'จำนวนลูกค้า',
  'payment_guest_count_value': '@count ท่าน',
  'payment_receipt_subtotal_label': 'ยอดรวมอาหาร',
  'payment_service_charge_rate_label': 'Service Charge @rate%',
  'payment_vat_rate_label': 'VAT @rate%',
  'payment_grand_total_label': 'รวมทั้งสิ้น',
  'payment_refund_list_title': 'รายการคืนเงิน',
  'payment_net_total_after_refund_label': 'ยอดสุทธิหลังคืนเงิน',
  'payment_thank_you_message': 'ขอบคุณที่ใช้บริการ 🙏',
  'payment_powered_by': 'Powered by PaynEat POS',

  // refund_dialog
  'payment_refund_amount_invalid': 'ยอดคืนต้องมากกว่า 0 และไม่เกิน @amount',
  'payment_refund_reason_required': 'กรุณาระบุเหตุผลที่คืนเงิน',
  'payment_refund_dialog_title': 'คืนเงิน',
  'payment_refund_max_amount_label': 'คืนได้สูงสุด @amount',
  'payment_refund_amount_label': 'ยอดที่คืน',
  'payment_refund_reason_label': 'เหตุผลที่คืนเงิน',
  'payment_refund_reason_hint': 'เช่น ลูกค้าคืนอาหาร / เก็บเงินผิด',
  'payment_confirm_refund_button': 'ยืนยันคืนเงิน',

  // receipt_controller (snackbar)
  'payment_refund_success': 'คืนเงินเรียบร้อย',
  'payment_print_success': 'พิมพ์ใบเสร็จแล้ว',

  // demo_store_payments / demo_store_refunds (ApiException messages)
  'payment_error_items_not_in_order': 'มีรายการที่ไม่ได้อยู่ในออเดอร์นี้',
  'payment_error_item_already_paid': '"@name" ถูกจ่ายไปแล้ว',
  'payment_error_item_cancelled': '"@name" ถูกยกเลิกไปแล้ว เลือกจ่ายไม่ได้',
  'payment_error_order_cancelled': 'ออเดอร์นี้ถูกยกเลิกแล้ว',
  'payment_error_shift_required': 'ต้องเปิดกะก่อนจึงจะรับชำระเงินได้',
  'payment_error_amount_exceeds_remaining':
      'ยอดชำระเกินยอดคงเหลือ (คงเหลือ @remaining บาท)',
  'payment_error_received_less_than_amount':
      'เงินที่รับมาต้องไม่น้อยกว่ายอดที่ชำระ',
  'payment_error_payment_not_found': 'ไม่พบรายการชำระเงินนี้',
  'payment_error_refund_exceeds_refundable':
      'คืนเงินเกินยอดที่คืนได้ (คืนได้สูงสุด @amount บาท)',
};

const Map<String, String> paymentTranslationsEn = {
  // checkout_page
  'payment_checkout_title': 'Checkout / Close bill',
  'payment_order_not_found': 'Order not found',
  'payment_no_shift_banner':
      'No shift open yet. Open a shift before accepting payment.',
  'payment_go_open_shift': 'Open shift',
  'payment_already_paid_section_title': 'Already paid',
  'payment_remaining_due_label': 'Remaining due',
  'payment_method_section_title': 'Payment method',
  'payment_amount_this_round_label': 'Amount to collect this round',
  'payment_amount_this_round_helper': 'Change this only for a partial payment',
  'payment_received_label': 'Amount received',
  'payment_received_helper': 'Enter the cash handed over — change is calculated for you',
  'payment_exact_amount_label': 'Exact',
  'payment_change_due_label': 'Change due',
  'payment_reference_label': 'Reference number (optional)',
  'payment_reference_hint': 'e.g. slip number / last 4 card digits',
  'payment_submit_button': 'Charge @amount',

  // checkout_controller / split_bill_controller (snackbar)
  'payment_bill_closed_success': 'Bill closed successfully',
  'payment_partial_paid_success': 'Payment received. @amount THB remaining',

  // split_bill_page
  'payment_split_bill_title': 'Split bill',
  'payment_order_already_paid': 'This order has already been fully paid',
  'payment_split_bill_instructions':
      'Tap to select the items this person will pay for, then charge — repeat until all items are paid',
  'payment_item_paid_label': 'Paid',
  'payment_item_quantity_label': '@count items',
  'payment_select_items_hint': 'Select items above to see the amount due',
  'payment_selected_subtotal_label': 'Selected items subtotal',
  'payment_discount_label': 'Discount',
  'payment_service_charge_label': 'Service Charge',
  'payment_vat_label': 'VAT',
  'payment_amount_due_this_round_label': 'Amount due this round',

  // receipt_page
  'payment_receipt_title': 'Receipt',
  'payment_print_receipt_tooltip': 'Print receipt',
  'payment_back_to_home_tooltip': 'Back to home',
  'payment_receipt_not_found': 'Receipt data not found',
  'payment_receipt_subtitle': 'Receipt / Abbreviated tax invoice',
  'payment_receipt_order_code_label': 'Order no.',
  'payment_receipt_date_label': 'Date',
  'payment_receipt_table_type_label': 'Table / Type',
  'payment_receipt_staff_label': 'Staff',
  'payment_receipt_guest_count_label': 'Guest count',
  'payment_guest_count_value': '@count guests',
  'payment_receipt_subtotal_label': 'Food subtotal',
  'payment_service_charge_rate_label': 'Service Charge @rate%',
  'payment_vat_rate_label': 'VAT @rate%',
  'payment_grand_total_label': 'Grand total',
  'payment_refund_list_title': 'Refunds',
  'payment_net_total_after_refund_label': 'Net total after refund',
  'payment_thank_you_message': 'Thank you for your visit 🙏',
  'payment_powered_by': 'Powered by PaynEat POS',

  // refund_dialog
  'payment_refund_amount_invalid':
      'Refund amount must be greater than 0 and not exceed @amount',
  'payment_refund_reason_required': 'Please provide a reason for the refund',
  'payment_refund_dialog_title': 'Refund',
  'payment_refund_max_amount_label': 'Maximum refundable @amount',
  'payment_refund_amount_label': 'Refund amount',
  'payment_refund_reason_label': 'Refund reason',
  'payment_refund_reason_hint':
      'e.g. customer returned food / charged incorrectly',
  'payment_confirm_refund_button': 'Confirm refund',

  // receipt_controller (snackbar)
  'payment_refund_success': 'Refund completed successfully',
  'payment_print_success': 'Receipt printed',

  // demo_store_payments / demo_store_refunds (ApiException messages)
  'payment_error_items_not_in_order': 'Some items are not part of this order',
  'payment_error_item_already_paid': '"@name" has already been paid',
  'payment_error_item_cancelled':
      '"@name" has been cancelled and cannot be selected for payment',
  'payment_error_order_cancelled': 'This order has been cancelled',
  'payment_error_shift_required':
      'You must open a shift before accepting payment',
  'payment_error_amount_exceeds_remaining':
      'Payment amount exceeds the remaining balance (remaining @remaining THB)',
  'payment_error_received_less_than_amount':
      'The amount received must not be less than the amount charged',
  'payment_error_payment_not_found': 'This payment record was not found',
  'payment_error_refund_exceeds_refundable':
      'Refund amount exceeds what is refundable (maximum @amount THB)',
};
