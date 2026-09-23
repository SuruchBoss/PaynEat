/// คำแปลของดอกเบี้ยผิดนัด ใบลดหนี้ และ PDF/อีเมลเอกสารลูกหนี้
/// (ดู docs/tickets/21-late-fees-credit-notes.md, docs/tickets/23-document-pdf-email.md)
const Map<String, String> receivableDocumentTranslationsTh = {
  // ดอกเบี้ยผิดนัด
  'receivable_late_fee_button': 'คิดดอกเบี้ยผิดนัด',
  'receivable_late_fee_dialog_title': 'คิดดอกเบี้ยผิดนัดชำระ',
  'receivable_late_fee_rate_unset':
      'ร้านยังไม่ได้ตั้งอัตราดอกเบี้ยผิดนัด — ผู้ดูแลระบบตั้งได้ที่หน้าตั้งค่า หัวข้อ "ลูกหนี้ขายเชื่อ"',
  'receivable_late_fee_terms':
      'อัตรา @rate% ต่อปี · ผ่อนผัน @grace วันหลังครบกำหนด · คิดถึงวันที่ @date',
  'receivable_late_fee_nothing':
      'ไม่มีบิลที่ต้องคิดดอกเบี้ยเพิ่ม ณ วันนี้ (ยังไม่เลยวันผ่อนผัน หรือคิดถึงวันนี้ไปแล้ว)',
  'receivable_late_fee_line': '@from – @to (@days วัน) เงินต้นค้าง @principal',
  'receivable_late_fee_total': 'ดอกเบี้ยรวม',
  'receivable_late_fee_note_label': 'หมายเหตุ (ไม่บังคับ)',
  'receivable_late_fee_formula':
      'ดอกเบี้ยธรรมดา = เงินต้นค้าง × อัตราต่อปี × จำนวนวัน ÷ 365 บวกเข้ายอดค้างของแต่ละบิล',
  'receivable_late_fee_issue': 'ออกใบแจ้งดอกเบี้ย',
  'receivable_late_fee_success': 'ออกใบแจ้งดอกเบี้ย @no แล้ว',
  'receivable_late_fee_title': 'ใบแจ้งดอกเบี้ยผิดนัด',
  'receivable_late_fee_rate': 'อัตรา',
  'receivable_late_fee_rate_value': '@rate% ต่อปี',
  'receivable_late_fee_as_of': 'คิดถึงวันที่',
  'receivable_late_fee_void_title':
      'ยกเลิกใบแจ้งดอกเบี้ย (ยกเว้นดอกเบี้ยให้ลูกค้า)',
  'receivable_late_fee_voided':
      'ยกเลิกใบแจ้งดอกเบี้ยแล้ว — ยอดค้างลดลงตามดอกเบี้ยในใบ',
  'receivable_late_fees_title': 'ใบแจ้งดอกเบี้ยผิดนัด',
  'receivable_late_fee_tile': '@date · @rate% ต่อปี · @count บิล',
  'receivable_invoice_interest': 'รวมดอกเบี้ย @amount',
  // ใบลดหนี้
  'receivable_credit_note_button': 'ออกใบลดหนี้',
  'receivable_credit_note_dialog_title': 'ลดหนี้บิลขายเชื่อ',
  'receivable_credit_note_invoice_label': 'บิลที่ลดหนี้',
  'receivable_credit_note_invoice_option': '#@code (ค้าง @amount)',
  'receivable_credit_note_amount_label': 'ยอดลดหนี้ (รวม VAT)',
  'receivable_credit_note_max': 'ลดได้สูงสุด @amount',
  'receivable_credit_note_amount_invalid':
      'ยอดต้องมากกว่า 0 และไม่เกินยอดที่ลดได้',
  'receivable_credit_note_reason_label': 'เหตุผล (พิมพ์ลงใบลดหนี้)',
  'receivable_credit_note_reason_hint': 'เช่น สินค้าชำรุด 2 กก. ลูกค้าส่งคืน',
  'receivable_credit_note_issue': 'ลดหนี้และออกใบลดหนี้',
  'receivable_credit_note_success': 'ออกใบลดหนี้ @no แล้ว',
  'receivable_credit_note_title': 'ใบลดหนี้',
  'receivable_credit_note_original': 'มูลค่าตามบิลเดิม #@code',
  'receivable_credit_note_previous': 'ลดหนี้ไปแล้วก่อนหน้านี้',
  'receivable_credit_note_correct': 'มูลค่าที่ถูกต้อง',
  'receivable_credit_note_total': 'ผลต่าง (ลดหนี้ครั้งนี้)',
  'receivable_credit_note_tax_invoice': 'ใบกำกับภาษีเดิม',
  'receivable_credit_note_base': 'มูลค่าก่อนภาษี',
  'receivable_credit_note_vat': 'ภาษีมูลค่าเพิ่มของผลต่าง',
  'receivable_credit_note_reason': 'เหตุผลที่ลดหนี้: @reason',
  'receivable_credit_notes_title': 'ใบลดหนี้',
  // PDF + อีเมล
  'receivable_download_pdf': 'ดาวน์โหลด PDF',
  'receivable_send_email': 'ส่งอีเมล',
  'receivable_email_title': 'ส่ง @no ทางอีเมล',
  'receivable_email_to_label': 'อีเมลผู้รับ',
  'receivable_email_to_help':
      'บันทึกอีเมลไว้ในบัญชีเครดิตของลูกค้า ครั้งหน้าจะเติมให้เอง',
  'receivable_email_message_label': 'ข้อความถึงลูกค้า (ไม่บังคับ)',
  'receivable_email_message_hint': 'เช่น รบกวนชำระภายในสิ้นเดือนนะคะ',
  'receivable_email_sent': 'ส่งอีเมลถึง @to แล้ว (แนบ PDF)',
  'receivable_email_sent_demo':
      'จำลองการส่งอีเมลถึง @to แล้ว — โหมดสาธิตไม่ได้ส่งจริง',
  'receivable_email_history': 'ประวัติการส่งอีเมล',
  'receivable_email_history_line': '@to · @date · โดย @name',
  'receivable_pdf_demo_unavailable':
      'โหมดสาธิตไม่มีเซิร์ฟเวอร์สร้าง PDF — ดูและพิมพ์จากจอได้',
  // ข้อผิดพลาด (Demo Mode — ข้อความเดียวกับ backend)
  'receivable_error_late_fee_rate_unset':
      'ยังไม่ได้ตั้งอัตราดอกเบี้ยผิดนัด — ตั้งได้ที่หน้าตั้งค่า',
  'receivable_error_late_fee_nothing':
      'ไม่มีบิลที่ต้องคิดดอกเบี้ยเพิ่ม ณ วันนี้',
  'receivable_error_late_fee_not_found': 'ไม่พบใบแจ้งดอกเบี้ยนี้',
  'receivable_error_late_fee_already_voided':
      'ใบแจ้งดอกเบี้ยนี้ถูกยกเลิกไปแล้ว',
  'receivable_error_late_fee_paid':
      'ดอกเบี้ยของบิล #@code ถูกชำระไปแล้ว — ยกเลิกใบเสร็จรับชำระก่อนจึงยกเลิกใบแจ้งนี้ได้',
  'receivable_error_credit_note_not_credit':
      'ใบลดหนี้ออกได้เฉพาะบิลขายเชื่อ — บิลที่จ่ายแล้วให้ใช้คืนเงินตามปกติ',
  'receivable_error_credit_note_not_found': 'ไม่พบใบลดหนี้นี้',
  'receivable_error_email_voided': '@titleนี้ถูกยกเลิกแล้ว ส่งให้ลูกค้าไม่ได้',
  'receivable_error_email_no_recipient':
      'ลูกค้ารายนี้ยังไม่มีอีเมล — ระบุอีเมลผู้รับ หรือบันทึกอีเมลไว้ในบัญชีเครดิตของลูกค้า',
};

const Map<String, String> receivableDocumentTranslationsEn = {
  'receivable_late_fee_button': 'Charge late interest',
  'receivable_late_fee_dialog_title': 'Charge late-payment interest',
  'receivable_late_fee_rate_unset':
      'No late-payment interest rate is set — an admin can set it in Settings under "Credit customers"',
  'receivable_late_fee_terms':
      '@rate% per year · @grace grace days after due date · charged through @date',
  'receivable_late_fee_nothing':
      'No bills need interest today (still within grace, or already charged through today)',
  'receivable_late_fee_line':
      '@from – @to (@days days) on principal @principal',
  'receivable_late_fee_total': 'Total interest',
  'receivable_late_fee_note_label': 'Note (optional)',
  'receivable_late_fee_formula':
      'Simple interest = unpaid principal × annual rate × days ÷ 365, added to each bill\'s balance',
  'receivable_late_fee_issue': 'Issue interest notice',
  'receivable_late_fee_success': 'Interest notice @no issued',
  'receivable_late_fee_title': 'Late-payment interest notice',
  'receivable_late_fee_rate': 'Rate',
  'receivable_late_fee_rate_value': '@rate% per year',
  'receivable_late_fee_as_of': 'Charged through',
  'receivable_late_fee_void_title': 'Void interest notice (waive the interest)',
  'receivable_late_fee_voided':
      'Interest notice voided — balance reduced by its interest',
  'receivable_late_fees_title': 'Late-payment interest',
  'receivable_late_fee_tile': '@date · @rate% p.a. · @count bills',
  'receivable_invoice_interest': 'incl. interest @amount',
  'receivable_credit_note_button': 'Issue credit note',
  'receivable_credit_note_dialog_title': 'Credit a credit-sale bill',
  'receivable_credit_note_invoice_label': 'Bill to credit',
  'receivable_credit_note_invoice_option': '#@code (owes @amount)',
  'receivable_credit_note_amount_label': 'Credit amount (incl. VAT)',
  'receivable_credit_note_max': 'Up to @amount',
  'receivable_credit_note_amount_invalid':
      'Amount must be above 0 and within the creditable amount',
  'receivable_credit_note_reason_label': 'Reason (printed on the credit note)',
  'receivable_credit_note_reason_hint':
      'e.g. 2 kg damaged, returned by customer',
  'receivable_credit_note_issue': 'Credit and issue note',
  'receivable_credit_note_success': 'Credit note @no issued',
  'receivable_credit_note_title': 'Credit note',
  'receivable_credit_note_original': 'Original bill value #@code',
  'receivable_credit_note_previous': 'Previously credited',
  'receivable_credit_note_correct': 'Corrected value',
  'receivable_credit_note_total': 'Difference (this credit)',
  'receivable_credit_note_tax_invoice': 'Original tax invoice',
  'receivable_credit_note_base': 'Value before VAT',
  'receivable_credit_note_vat': 'VAT on the difference',
  'receivable_credit_note_reason': 'Reason: @reason',
  'receivable_credit_notes_title': 'Credit notes',
  'receivable_download_pdf': 'Download PDF',
  'receivable_send_email': 'Send e-mail',
  'receivable_email_title': 'E-mail @no',
  'receivable_email_to_label': 'Recipient e-mail',
  'receivable_email_to_help':
      'Save an e-mail on the customer\'s credit account to pre-fill it next time',
  'receivable_email_message_label': 'Message to the customer (optional)',
  'receivable_email_message_hint': 'e.g. Please settle by the end of the month',
  'receivable_email_sent': 'E-mailed to @to (PDF attached)',
  'receivable_email_sent_demo':
      'Simulated e-mail to @to — Demo Mode sends nothing',
  'receivable_email_history': 'E-mail history',
  'receivable_email_history_line': '@to · @date · by @name',
  'receivable_pdf_demo_unavailable':
      'Demo Mode has no server to render PDFs — view and print on screen instead',
  'receivable_error_late_fee_rate_unset':
      'No late-payment interest rate is set — set it in Settings',
  'receivable_error_late_fee_nothing': 'No bills need interest today',
  'receivable_error_late_fee_not_found': 'Interest notice not found',
  'receivable_error_late_fee_already_voided':
      'This interest notice is already voided',
  'receivable_error_late_fee_paid':
      'Interest on bill #@code has been paid — void the payment receipt first',
  'receivable_error_credit_note_not_credit':
      'Credit notes are for credit-sale bills only — refund paid bills as usual',
  'receivable_error_credit_note_not_found': 'Credit note not found',
  'receivable_error_email_voided':
      'This @title is voided and cannot be sent to the customer',
  'receivable_error_email_no_recipient':
      'This customer has no e-mail — enter a recipient or save one on their credit account',
};

const Map<String, String> receivableDocumentTranslationsKo = {
  'receivable_late_fee_button': '연체 이자 부과',
  'receivable_late_fee_dialog_title': '연체 이자 부과',
  'receivable_late_fee_rate_unset':
      '연체 이자율이 설정되지 않았습니다 — 관리자가 설정 화면의 "외상 고객"에서 설정할 수 있습니다',
  'receivable_late_fee_terms': '연 @rate% · 만기 후 유예 @grace일 · @date까지 계산',
  'receivable_late_fee_nothing': '오늘 이자를 부과할 청구서가 없습니다 (유예 기간이거나 이미 오늘까지 계산됨)',
  'receivable_late_fee_line': '@from – @to (@days일) 미수 원금 @principal',
  'receivable_late_fee_total': '이자 합계',
  'receivable_late_fee_note_label': '메모 (선택)',
  'receivable_late_fee_formula': '단리 = 미수 원금 × 연이율 × 일수 ÷ 365, 각 청구서 잔액에 더해집니다',
  'receivable_late_fee_issue': '이자 청구서 발행',
  'receivable_late_fee_success': '이자 청구서 @no 발행됨',
  'receivable_late_fee_title': '연체 이자 청구서',
  'receivable_late_fee_rate': '이율',
  'receivable_late_fee_rate_value': '연 @rate%',
  'receivable_late_fee_as_of': '계산 기준일',
  'receivable_late_fee_void_title': '이자 청구서 취소 (이자 면제)',
  'receivable_late_fee_voided': '이자 청구서가 취소되어 잔액이 줄었습니다',
  'receivable_late_fees_title': '연체 이자',
  'receivable_late_fee_tile': '@date · 연 @rate% · @count건',
  'receivable_invoice_interest': '이자 포함 @amount',
  'receivable_credit_note_button': '대변전표 발행',
  'receivable_credit_note_dialog_title': '외상 청구서 감액',
  'receivable_credit_note_invoice_label': '감액할 청구서',
  'receivable_credit_note_invoice_option': '#@code (미수 @amount)',
  'receivable_credit_note_amount_label': '감액 금액 (VAT 포함)',
  'receivable_credit_note_max': '최대 @amount',
  'receivable_credit_note_amount_invalid': '금액은 0보다 크고 감액 가능 금액 이하여야 합니다',
  'receivable_credit_note_reason_label': '사유 (대변전표에 인쇄)',
  'receivable_credit_note_reason_hint': '예: 2kg 불량, 고객 반품',
  'receivable_credit_note_issue': '감액 및 대변전표 발행',
  'receivable_credit_note_success': '대변전표 @no 발행됨',
  'receivable_credit_note_title': '대변전표',
  'receivable_credit_note_original': '원 청구 금액 #@code',
  'receivable_credit_note_previous': '이전 감액',
  'receivable_credit_note_correct': '정정 금액',
  'receivable_credit_note_total': '차액 (이번 감액)',
  'receivable_credit_note_tax_invoice': '원 세금계산서',
  'receivable_credit_note_base': '공급가액',
  'receivable_credit_note_vat': '차액의 부가세',
  'receivable_credit_note_reason': '감액 사유: @reason',
  'receivable_credit_notes_title': '대변전표',
  'receivable_download_pdf': 'PDF 다운로드',
  'receivable_send_email': '이메일 발송',
  'receivable_email_title': '@no 이메일 발송',
  'receivable_email_to_label': '받는 사람 이메일',
  'receivable_email_to_help': '고객 외상 계정에 이메일을 저장하면 다음부터 자동으로 입력됩니다',
  'receivable_email_message_label': '고객에게 보낼 메시지 (선택)',
  'receivable_email_message_hint': '예: 월말까지 결제 부탁드립니다',
  'receivable_email_sent': '@to 로 발송했습니다 (PDF 첨부)',
  'receivable_email_sent_demo': '@to 로 발송을 시뮬레이션했습니다 — 데모 모드는 실제로 보내지 않습니다',
  'receivable_email_history': '이메일 발송 내역',
  'receivable_email_history_line': '@to · @date · @name',
  'receivable_pdf_demo_unavailable': '데모 모드에는 PDF를 만들 서버가 없습니다 — 화면에서 보고 인쇄하세요',
  'receivable_error_late_fee_rate_unset': '연체 이자율이 설정되지 않았습니다 — 설정 화면에서 설정하세요',
  'receivable_error_late_fee_nothing': '오늘 이자를 부과할 청구서가 없습니다',
  'receivable_error_late_fee_not_found': '이자 청구서를 찾을 수 없습니다',
  'receivable_error_late_fee_already_voided': '이미 취소된 이자 청구서입니다',
  'receivable_error_late_fee_paid':
      '청구서 #@code 의 이자가 이미 결제되었습니다 — 먼저 수금 영수증을 취소하세요',
  'receivable_error_credit_note_not_credit':
      '대변전표는 외상 청구서에만 발행할 수 있습니다 — 결제된 청구서는 일반 환불을 사용하세요',
  'receivable_error_credit_note_not_found': '대변전표를 찾을 수 없습니다',
  'receivable_error_email_voided': '취소된 @title 은(는) 고객에게 보낼 수 없습니다',
  'receivable_error_email_no_recipient':
      '이 고객은 이메일이 없습니다 — 받는 사람을 입력하거나 외상 계정에 저장하세요',
};
