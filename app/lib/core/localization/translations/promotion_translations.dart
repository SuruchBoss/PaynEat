// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/// คำแปลของฟีเจอร์โปรโมชัน (ticket 05 — promotion engine)
const Map<String, String> promotionTranslationsTh = {
  // ชนิดโปรโมชัน
  'promotion_type_percent': 'ลดเปอร์เซ็นต์',
  'promotion_type_amount': 'ลดจำนวนเงิน',
  'promotion_type_bogo': 'ซื้อ 1 แถม 1',

  // แสดงในบิล/ใบเสร็จ
  'promotion_summary_label': 'โปรโมชัน: @name',

  // ข้อความ error จาก demo store (ฝั่งจำลอง backend) — ใช้ข้อความเดียวกับ backend จริง
  'promotion_error_not_found': 'ไม่พบโปรโมชันนี้',
  'promotion_error_code_taken': 'โค้ด "@code" มีโปรโมชันอื่นใช้อยู่แล้ว',
  'promotion_error_code_not_found': 'ไม่พบโค้ดส่วนลดนี้',
  'promotion_error_inactive': 'โค้ดนี้ถูกปิดใช้งานแล้ว',
  'promotion_error_expired': 'โค้ดนี้หมดอายุหรือยังไม่เริ่มใช้งาน',
  'promotion_error_not_in_time_window': 'ไม่ใช่ช่วงเวลาที่ร่วมรายการของโค้ดนี้',
  'promotion_error_min_subtotal_not_met': 'ยอดบิลยังไม่ถึงขั้นต่ำสำหรับโค้ดนี้',
  'promotion_error_no_matching_items': 'บิลนี้ไม่มีเมนูที่ร่วมรายการกับโค้ดนี้',

  // ผลลัพธ์การกระทำในหน้ารายละเอียดออเดอร์
  'promotion_redeem_success': 'ใช้โค้ดส่วนลดแล้ว',
  'promotion_removed_success': 'เอาโปรโมชันออกแล้ว',

  // กล่องโปรโมชัน/กรอกโค้ด (หน้ารายละเอียดออเดอร์)
  'promotion_dialog_title': 'โปรโมชัน/ส่วนลด',
  'promotion_dialog_none_available': 'ยังไม่มีโปรโมชันที่ใช้ได้กับบิลนี้ตอนนี้',
  'promotion_dialog_code_section': 'มีโค้ดส่วนลด?',
  'promotion_dialog_code_hint': 'กรอกโค้ดส่วนลด',
  'promotion_dialog_remove_button': 'เอาโปรโมชันออก',
  'promotion_dialog_apply_code_button': 'ใช้โค้ด',
  'promotion_dialog_badge_applied': 'กำลังใช้งาน',
  'promotion_dialog_badge_needs_code': 'ต้องกรอกโค้ด',
  'promotion_dialog_badge_auto': 'ใช้อัตโนมัติเมื่อเข้าเงื่อนไข',

  // หน้าจัดการโปรโมชัน (admin/manager)
  'promotion_add_button': 'เพิ่มโปรโมชัน',
  'promotion_empty_state': 'ยังไม่มีโปรโมชัน',
  'promotion_created_success': 'สร้างโปรโมชันแล้ว',
  'promotion_updated_success': 'แก้ไขโปรโมชันแล้ว',
  'promotion_deleted_success': 'ลบโปรโมชันแล้ว',
  'promotion_delete_title': 'ลบโปรโมชัน',
  'promotion_delete_confirm': 'ต้องการลบโปรโมชัน "@name" ใช่หรือไม่?',

  // ฟอร์มเพิ่ม/แก้ไขโปรโมชัน
  'promotion_form_add_title': 'เพิ่มโปรโมชัน',
  'promotion_form_edit_title': 'แก้ไขโปรโมชัน',
  'promotion_form_info_section': 'ข้อมูลโปรโมชัน',
  'promotion_form_name_label': 'ชื่อโปรโมชัน',
  'promotion_form_name_required': 'กรุณากรอกชื่อโปรโมชัน',
  'promotion_form_value_percent_label': 'ลดกี่เปอร์เซ็นต์',
  'promotion_form_value_amount_label': 'ลดกี่บาท',
  'promotion_form_value_invalid': 'กรุณากรอกจำนวนที่ถูกต้อง',
  'promotion_form_value_percent_max': 'ส่วนลดเปอร์เซ็นต์เกิน 100% ไม่ได้',
  'promotion_form_code_label': 'โค้ดส่วนลด (ถ้ามี)',
  'promotion_form_code_hint': 'ปล่อยว่าง = apply อัตโนมัติเมื่อเข้าเงื่อนไข',
  'promotion_form_active_label': 'เปิดใช้งาน',
  'promotion_form_conditions_section': 'เงื่อนไขการใช้งาน',
  'promotion_form_conditions_hint':
      'ไม่ระบุเงื่อนไข = ใช้ได้ทุกช่วงเวลา/ทั้งบิล',
  'promotion_form_days_label': 'วันที่ร่วมรายการ (ไม่เลือก = ทุกวัน)',
  'promotion_day_sun': 'อา',
  'promotion_day_mon': 'จ',
  'promotion_day_tue': 'อ',
  'promotion_day_wed': 'พ',
  'promotion_day_thu': 'พฤ',
  'promotion_day_fri': 'ศ',
  'promotion_day_sat': 'ส',
  'promotion_form_start_time_label': 'เวลาเริ่ม',
  'promotion_form_end_time_label': 'เวลาสิ้นสุด',
  'promotion_form_valid_from_label': 'เริ่มใช้วันที่',
  'promotion_form_valid_to_label': 'สิ้นสุดวันที่',
  'promotion_form_min_subtotal_label': 'ยอดขั้นต่ำ (ถ้ามี)',
  'promotion_form_categories_label':
      'หมวดหมู่ที่ร่วมรายการ (ไม่เลือก = ทั้งบิล)',
  'promotion_form_eligibility_hint':
      'เลือกได้ทั้งหมวดหมู่และเมนู ไม่เลือกเลย = ร่วมรายการทั้งบิล',
  'promotion_form_menu_items_label':
      'เมนูที่ร่วมรายการ (ไม่เลือก = ทุกเมนูในหมวดที่เลือก)',
  'promotion_form_submit_edit': 'บันทึกการแก้ไข',
};

const Map<String, String> promotionTranslationsEn = {
  'promotion_type_percent': 'Percent off',
  'promotion_type_amount': 'Amount off',
  'promotion_type_bogo': 'Buy 1 get 1',

  'promotion_summary_label': 'Promotion: @name',

  'promotion_error_not_found': 'Promotion not found',
  'promotion_error_code_taken':
      'Code "@code" is already used by another promotion',
  'promotion_error_code_not_found': 'This discount code was not found',
  'promotion_error_inactive': 'This code has been disabled',
  'promotion_error_expired': 'This code has expired or is not active yet',
  'promotion_error_not_in_time_window':
      'Not within the eligible time window for this code',
  'promotion_error_min_subtotal_not_met':
      'The bill has not reached the minimum spend for this code',
  'promotion_error_no_matching_items':
      'No eligible items on this bill for this code',

  'promotion_redeem_success': 'Discount code applied',
  'promotion_removed_success': 'Promotion removed',

  'promotion_dialog_title': 'Promotions / discount',
  'promotion_dialog_none_available':
      'No promotions available for this bill right now',
  'promotion_dialog_code_section': 'Have a discount code?',
  'promotion_dialog_code_hint': 'Enter discount code',
  'promotion_dialog_remove_button': 'Remove promotion',
  'promotion_dialog_apply_code_button': 'Apply code',
  'promotion_dialog_badge_applied': 'Applied',
  'promotion_dialog_badge_needs_code': 'Requires code',
  'promotion_dialog_badge_auto': 'Applies automatically when eligible',

  'promotion_add_button': 'Add promotion',
  'promotion_empty_state': 'No promotions yet',
  'promotion_created_success': 'Promotion created',
  'promotion_updated_success': 'Promotion updated',
  'promotion_deleted_success': 'Promotion deleted',
  'promotion_delete_title': 'Delete promotion',
  'promotion_delete_confirm': 'Delete promotion "@name"?',

  'promotion_form_add_title': 'Add promotion',
  'promotion_form_edit_title': 'Edit promotion',
  'promotion_form_info_section': 'Promotion details',
  'promotion_form_name_label': 'Promotion name',
  'promotion_form_name_required': 'Please enter a promotion name',
  'promotion_form_value_percent_label': 'Discount percent',
  'promotion_form_value_amount_label': 'Discount amount',
  'promotion_form_value_invalid': 'Please enter a valid amount',
  'promotion_form_value_percent_max': 'Percent discount cannot exceed 100%',
  'promotion_form_code_label': 'Discount code (optional)',
  'promotion_form_code_hint': 'Leave blank to auto-apply when eligible',
  'promotion_form_active_label': 'Active',
  'promotion_form_conditions_section': 'Eligibility conditions',
  'promotion_form_conditions_hint':
      'No conditions = valid at any time, for the whole bill',
  'promotion_form_days_label': 'Eligible days (none selected = every day)',
  'promotion_day_sun': 'Sun',
  'promotion_day_mon': 'Mon',
  'promotion_day_tue': 'Tue',
  'promotion_day_wed': 'Wed',
  'promotion_day_thu': 'Thu',
  'promotion_day_fri': 'Fri',
  'promotion_day_sat': 'Sat',
  'promotion_form_start_time_label': 'Start time',
  'promotion_form_end_time_label': 'End time',
  'promotion_form_valid_from_label': 'Valid from',
  'promotion_form_valid_to_label': 'Valid to',
  'promotion_form_min_subtotal_label': 'Minimum spend (optional)',
  'promotion_form_categories_label':
      'Eligible categories (none selected = whole bill)',
  'promotion_form_eligibility_hint':
      'You can pick categories and menu items — pick none for the whole bill',
  'promotion_form_menu_items_label':
      'Eligible menu items (none selected = every item in the selected categories)',
  'promotion_form_submit_edit': 'Save changes',
};

const Map<String, String> promotionTranslationsKo = {
  'promotion_type_percent': '퍼센트 할인',
  'promotion_type_amount': '금액 할인',
  'promotion_type_bogo': '1+1',
  'promotion_summary_label': '프로모션: @name',
  'promotion_error_not_found': '프로모션을 찾을 수 없습니다',
  'promotion_error_code_taken': '"@code" 코드는 다른 프로모션이 이미 사용 중입니다',
  'promotion_error_code_not_found': '해당 할인 코드를 찾을 수 없습니다',
  'promotion_error_inactive': '사용이 중지된 코드입니다',
  'promotion_error_expired': '만료되었거나 아직 시작되지 않은 코드입니다',
  'promotion_error_not_in_time_window': '이 코드를 사용할 수 있는 시간대가 아닙니다',
  'promotion_error_min_subtotal_not_met': '이 코드의 최소 결제 금액에 도달하지 않았습니다',
  'promotion_error_no_matching_items': '이 주문에는 코드를 적용할 수 있는 메뉴가 없습니다',
  'promotion_redeem_success': '할인 코드를 적용했습니다',
  'promotion_removed_success': '프로모션을 해제했습니다',
  'promotion_dialog_title': '프로모션 / 할인',
  'promotion_dialog_none_available': '지금 이 주문에 적용할 수 있는 프로모션이 없습니다',
  'promotion_dialog_code_section': '할인 코드가 있으신가요?',
  'promotion_dialog_code_hint': '할인 코드 입력',
  'promotion_dialog_remove_button': '프로모션 해제',
  'promotion_dialog_apply_code_button': '코드 적용',
  'promotion_dialog_badge_applied': '적용됨',
  'promotion_dialog_badge_needs_code': '코드 필요',
  'promotion_dialog_badge_auto': '조건을 만족하면 자동 적용',
  'promotion_add_button': '프로모션 추가',
  'promotion_empty_state': '등록된 프로모션이 없습니다',
  'promotion_created_success': '프로모션을 등록했습니다',
  'promotion_updated_success': '프로모션을 수정했습니다',
  'promotion_deleted_success': '프로모션을 삭제했습니다',
  'promotion_delete_title': '프로모션 삭제',
  'promotion_delete_confirm': '"@name" 프로모션을 삭제할까요?',
  'promotion_form_add_title': '프로모션 추가',
  'promotion_form_edit_title': '프로모션 수정',
  'promotion_form_info_section': '프로모션 정보',
  'promotion_form_name_label': '프로모션명',
  'promotion_form_name_required': '프로모션명을 입력해 주세요',
  'promotion_form_value_percent_label': '할인율',
  'promotion_form_value_amount_label': '할인 금액',
  'promotion_form_value_invalid': '올바른 값을 입력해 주세요',
  'promotion_form_value_percent_max': '할인율은 100%를 넘을 수 없습니다',
  'promotion_form_code_label': '할인 코드 (선택)',
  'promotion_form_code_hint': '비워 두면 조건을 만족할 때 자동으로 적용됩니다',
  'promotion_form_active_label': '사용 중',
  'promotion_form_conditions_section': '적용 조건',
  'promotion_form_conditions_hint': '조건을 두지 않으면 시간 제한 없이 주문 전체에 적용됩니다',
  'promotion_form_days_label': '적용 요일 (선택하지 않으면 매일)',
  'promotion_day_sun': '일',
  'promotion_day_mon': '월',
  'promotion_day_tue': '화',
  'promotion_day_wed': '수',
  'promotion_day_thu': '목',
  'promotion_day_fri': '금',
  'promotion_day_sat': '토',
  'promotion_form_start_time_label': '시작 시각',
  'promotion_form_end_time_label': '종료 시각',
  'promotion_form_valid_from_label': '시작일',
  'promotion_form_valid_to_label': '종료일',
  'promotion_form_min_subtotal_label': '최소 결제 금액 (선택)',
  'promotion_form_categories_label': '적용 카테고리 (선택하지 않으면 주문 전체)',
  'promotion_form_eligibility_hint':
      '카테고리와 메뉴를 함께 지정할 수 있습니다 — 아무것도 고르지 않으면 주문 전체에 적용됩니다',
  'promotion_form_menu_items_label': '적용 메뉴 (선택하지 않으면 선택한 카테고리의 모든 메뉴)',
  'promotion_form_submit_edit': '변경사항 저장',
};
