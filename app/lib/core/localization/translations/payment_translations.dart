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
  'payment_received_helper':
      'ใส่จำนวนเงินที่ลูกค้ายื่นให้ ระบบจะคิดเงินทอนให้เอง',
  'payment_exact_amount_label': 'พอดี',
  'payment_change_due_label': 'เงินทอน',
  'payment_reference_label': 'เลขอ้างอิง (ถ้ามี)',
  'payment_reference_hint': 'เช่น เลขที่สลิป / 4 ตัวท้ายบัตร',
  'payment_submit_button': 'รับชำระ @amount',

  // promptpay_qr_view (ดู docs/tickets/16-promptpay-qr.md)
  'payment_promptpay_qr_semantics': 'คิวอาร์โค้ดพร้อมเพย์สำหรับรับชำระเงิน',
  'payment_promptpay_scan_instruction':
      'ให้ลูกค้าสแกนจ่ายด้วยแอปธนาคาร แล้วเช็คสลิป/แอปว่าเงินเข้าจริงก่อนกดยืนยันรับชำระ',
  'payment_promptpay_amount_required': 'กรอกยอดเงินก่อนเพื่อสร้าง QR',

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
  'payment_error_points_requires_customer':
      'ต้องผูกลูกค้ากับออเดอร์นี้ก่อนจึงใช้แต้มสะสมได้',
  'payment_error_points_insufficient': 'แต้มสะสมของลูกค้าไม่พอ',
  'payment_error_points_value_exceeds_amount':
      'แต้มที่ใช้มีมูลค่าเกินยอดที่ต้องชำระรอบนี้',

  // checkout_page — ส่วนแลกแต้มสะสม (ดู docs/tickets/09-customer-loyalty.md)
  'payment_loyalty_customer_label': 'ลูกค้า: @name',
  'payment_loyalty_points_balance': 'แต้มคงเหลือ @points',
  'payment_loyalty_redeem_label': 'ใช้แต้มแลกส่วนลด',
  'payment_loyalty_redeem_max_button': 'ใช้สูงสุด',
  'payment_loyalty_redeem_value': 'ลด @value บาทจากแต้มสะสม',
  'payment_loyalty_no_points_available': 'ยังใช้แต้มแลกส่วนลดไม่ได้ตอนนี้',
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
  'payment_received_helper':
      'Enter the cash handed over — change is calculated for you',
  'payment_exact_amount_label': 'Exact',
  'payment_change_due_label': 'Change due',
  'payment_reference_label': 'Reference number (optional)',
  'payment_reference_hint': 'e.g. slip number / last 4 card digits',
  'payment_submit_button': 'Charge @amount',

  // promptpay_qr_view (see docs/tickets/16-promptpay-qr.md)
  'payment_promptpay_qr_semantics': 'PromptPay QR code for payment',
  'payment_promptpay_scan_instruction':
      'Have the customer scan with their banking app, then check the slip/app before confirming payment',
  'payment_promptpay_amount_required':
      'Enter an amount first to generate the QR',

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
  'payment_error_points_requires_customer':
      'This order must be linked to a customer before redeeming points',
  'payment_error_points_insufficient':
      'The customer does not have enough points',
  'payment_error_points_value_exceeds_amount':
      'The value of the points redeemed exceeds the amount due this round',

  // checkout_page — loyalty points redemption section
  'payment_loyalty_customer_label': 'Customer: @name',
  'payment_loyalty_points_balance': '@points points left',
  'payment_loyalty_redeem_label': 'Redeem points for a discount',
  'payment_loyalty_redeem_max_button': 'Use max',
  'payment_loyalty_redeem_value': '@value THB off from redeemed points',
  'payment_loyalty_no_points_available': 'Points cannot be redeemed right now',
};

const Map<String, String> paymentTranslationsKo = {
  'payment_checkout_title': '결제 / 마감',
  'payment_order_not_found': '주문을 찾을 수 없습니다',
  'payment_no_shift_banner': '아직 근무가 시작되지 않았습니다. 결제를 받기 전에 근무를 시작해 주세요.',
  'payment_go_open_shift': '근무 시작',
  'payment_already_paid_section_title': '결제 완료 금액',
  'payment_remaining_due_label': '남은 금액',
  'payment_method_section_title': '결제 수단',
  'payment_amount_this_round_label': '이번에 받을 금액',
  'payment_amount_this_round_helper': '부분 결제일 때만 금액을 바꾸세요',
  'payment_received_label': '받은 금액',
  'payment_received_helper': '받은 현금을 입력하면 거스름돈이 계산됩니다',
  'payment_exact_amount_label': '정확히',
  'payment_change_due_label': '거스름돈',
  'payment_reference_label': '참조 번호 (선택)',
  'payment_reference_hint': '예: 이체 확인번호 / 카드 뒷 4자리',
  'payment_submit_button': '@amount 결제',
  'payment_promptpay_qr_semantics': '결제용 프롬프트페이 QR 코드',
  'payment_promptpay_scan_instruction':
      '손님이 은행 앱으로 스캔하게 한 뒤, 이체 확인 화면을 보고 결제를 확정하세요',
  'payment_promptpay_amount_required': 'QR을 만들려면 먼저 금액을 입력하세요',
  'payment_bill_closed_success': '결제를 완료했습니다',
  'payment_partial_paid_success': '결제를 받았습니다. @amount THB 남았습니다',
  'payment_split_bill_title': '분할 결제',
  'payment_order_already_paid': '이 주문은 이미 전액 결제되었습니다',
  'payment_split_bill_instructions':
      '이 손님이 낼 메뉴를 눌러 선택한 뒤 결제하세요 — 모든 메뉴가 결제될 때까지 반복합니다',
  'payment_item_paid_label': '결제됨',
  'payment_item_quantity_label': '@count개',
  'payment_select_items_hint': '위에서 메뉴를 선택하면 금액이 표시됩니다',
  'payment_selected_subtotal_label': '선택한 메뉴 합계',
  'payment_discount_label': '할인',
  'payment_service_charge_label': '서비스 차지',
  'payment_vat_label': '부가가치세',
  'payment_amount_due_this_round_label': '이번에 받을 금액',
  'payment_receipt_title': '영수증',
  'payment_print_receipt_tooltip': '영수증 출력',
  'payment_back_to_home_tooltip': '홈으로',
  'payment_receipt_not_found': '영수증 데이터를 찾을 수 없습니다',
  'payment_receipt_subtitle': '영수증 / 간이 세금계산서',
  'payment_receipt_order_code_label': '주문 번호',
  'payment_receipt_date_label': '일시',
  'payment_receipt_table_type_label': '테이블 / 유형',
  'payment_receipt_staff_label': '담당',
  'payment_receipt_guest_count_label': '인원',
  'payment_guest_count_value': '@count명',
  'payment_receipt_subtotal_label': '음식 합계',
  'payment_service_charge_rate_label': '서비스 차지 @rate%',
  'payment_vat_rate_label': '부가가치세 @rate%',
  'payment_grand_total_label': '총 합계',
  'payment_refund_list_title': '환불',
  'payment_net_total_after_refund_label': '환불 후 순합계',
  'payment_thank_you_message': '이용해 주셔서 감사합니다 🙏',
  'payment_powered_by': 'Powered by PaynEat POS',
  'payment_refund_amount_invalid': '환불 금액은 0보다 크고 @amount 이하여야 합니다',
  'payment_refund_reason_required': '환불 사유를 입력해 주세요',
  'payment_refund_dialog_title': '환불',
  'payment_refund_max_amount_label': '환불 가능 금액 @amount',
  'payment_refund_amount_label': '환불 금액',
  'payment_refund_reason_label': '환불 사유',
  'payment_refund_reason_hint': '예: 손님이 음식을 반품함 / 금액을 잘못 청구함',
  'payment_confirm_refund_button': '환불 확정',
  'payment_refund_success': '환불을 완료했습니다',
  'payment_print_success': '영수증을 출력했습니다',
  'payment_error_items_not_in_order': '이 주문에 없는 메뉴가 포함되어 있습니다',
  'payment_error_item_already_paid': '"@name"은(는) 이미 결제되었습니다',
  'payment_error_item_cancelled': '"@name"은(는) 취소된 메뉴여서 결제 대상으로 선택할 수 없습니다',
  'payment_error_order_cancelled': '취소된 주문입니다',
  'payment_error_shift_required': '결제를 받으려면 먼저 근무를 시작해야 합니다',
  'payment_error_amount_exceeds_remaining':
      '결제 금액이 남은 금액을 초과합니다 (남은 금액 @remaining THB)',
  'payment_error_received_less_than_amount': '받은 금액은 청구 금액보다 적을 수 없습니다',
  'payment_error_payment_not_found': '해당 결제 내역을 찾을 수 없습니다',
  'payment_error_refund_exceeds_refundable':
      '환불 금액이 환불 가능 금액을 초과합니다 (최대 @amount THB)',
  'payment_error_points_requires_customer': '적립금을 사용하려면 주문에 고객을 먼저 연결해야 합니다',
  'payment_error_points_insufficient': '고객의 적립금이 부족합니다',
  'payment_error_points_value_exceeds_amount': '사용하려는 적립금이 이번에 받을 금액을 초과합니다',
  'payment_loyalty_customer_label': '고객: @name',
  'payment_loyalty_points_balance': '@points P 보유',
  'payment_loyalty_redeem_label': '적립금으로 할인받기',
  'payment_loyalty_redeem_max_button': '최대 사용',
  'payment_loyalty_redeem_value': '적립금 사용으로 @value THB 할인',
  'payment_loyalty_no_points_available': '지금은 적립금을 사용할 수 없습니다',
};
