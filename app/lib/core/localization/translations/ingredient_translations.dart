/// คำแปลของฟีเจอร์ ingredient (วัตถุดิบ/สต๊อก — ดู docs/tickets/06-inventory-stock.md)
const Map<String, String> ingredientTranslationsTh = {
  // List page
  'ingredient_add_button': 'เพิ่มวัตถุดิบ',
  'ingredient_low_stock_filter': 'ใกล้หมดเท่านั้น',
  'ingredient_empty_state': 'ยังไม่มีวัตถุดิบในระบบ',
  'ingredient_low_stock_badge': 'ใกล้หมด',
  'ingredient_stock_summary':
      'เหลือ @stock @unit (แจ้งเตือนที่ @threshold @unit)',
  'ingredient_adjust_stock_tooltip': 'ปรับสต๊อก',

  // Adjust stock dialog
  'ingredient_adjust_stock_title': 'ปรับสต๊อก "@name"',
  'ingredient_current_stock_label': 'สต๊อกปัจจุบัน: @stock @unit',
  'ingredient_receive_stock_option': 'รับเข้า',
  'ingredient_deduct_stock_option': 'ตัดออก',
  'ingredient_adjust_amount_label': 'จำนวน',
  'ingredient_adjust_apply_button': 'บันทึก',

  // Form
  'ingredient_form_add_title': 'เพิ่มวัตถุดิบใหม่',
  'ingredient_form_edit_title': 'แก้ไขวัตถุดิบ',
  'ingredient_form_info_section': 'ข้อมูลวัตถุดิบ',
  'ingredient_form_name_label': 'ชื่อวัตถุดิบ *',
  'ingredient_form_name_required': 'กรุณากรอกชื่อวัตถุดิบ',
  'ingredient_form_unit_label': 'หน่วย *',
  'ingredient_form_unit_hint': 'เช่น กก., ลิตร, ชิ้น',
  'ingredient_form_unit_required': 'กรุณากรอกหน่วย',
  'ingredient_form_current_stock_label': 'สต๊อกเริ่มต้น',
  'ingredient_form_threshold_label': 'แจ้งเตือนเมื่อเหลือ',
  'ingredient_form_current_stock_locked_hint':
      'แก้ไขสต๊อกภายหลังต้องใช้ปุ่ม "ปรับสต๊อก" ในหน้ารายการ',
  'ingredient_form_submit_edit': 'บันทึกการแก้ไข',

  // Controller feedback messages
  'ingredient_created_success': 'เพิ่มวัตถุดิบใหม่แล้ว',
  'ingredient_updated_success': 'บันทึกการแก้ไขแล้ว',
  'ingredient_stock_adjusted_success': 'ปรับสต๊อกแล้ว',
  'ingredient_delete_title': 'ลบวัตถุดิบ',
  'ingredient_delete_confirm': 'ต้องการลบ "@name" ออกจากระบบใช่หรือไม่?',
  'ingredient_deleted_success': 'ลบวัตถุดิบแล้ว',

  // Demo store errors
  'ingredient_error_not_found': 'ไม่พบวัตถุดิบนี้',
  'ingredient_error_zero_delta': 'ต้องระบุจำนวนที่เปลี่ยนแปลงไม่เท่ากับ 0',
  'ingredient_error_linked_cannot_delete':
      'ลบไม่ได้ เพราะวัตถุดิบนี้ถูกผูกกับเมนูอยู่',
  'ingredient_error_duplicate_link': 'เลือกวัตถุดิบซ้ำกันในเมนูเดียวไม่ได้',
  'ingredient_error_link_not_found': 'ไม่พบวัตถุดิบที่เลือก',
};

const Map<String, String> ingredientTranslationsEn = {
  // List page
  'ingredient_add_button': 'Add ingredient',
  'ingredient_low_stock_filter': 'Low stock only',
  'ingredient_empty_state': 'No ingredients yet',
  'ingredient_low_stock_badge': 'Low stock',
  'ingredient_stock_summary': '@stock @unit left (alerts at @threshold @unit)',
  'ingredient_adjust_stock_tooltip': 'Adjust stock',

  // Adjust stock dialog
  'ingredient_adjust_stock_title': 'Adjust stock for "@name"',
  'ingredient_current_stock_label': 'Current stock: @stock @unit',
  'ingredient_receive_stock_option': 'Receive',
  'ingredient_deduct_stock_option': 'Deduct',
  'ingredient_adjust_amount_label': 'Amount',
  'ingredient_adjust_apply_button': 'Save',

  // Form
  'ingredient_form_add_title': 'Add new ingredient',
  'ingredient_form_edit_title': 'Edit ingredient',
  'ingredient_form_info_section': 'Ingredient information',
  'ingredient_form_name_label': 'Ingredient name *',
  'ingredient_form_name_required': 'Please enter an ingredient name',
  'ingredient_form_unit_label': 'Unit *',
  'ingredient_form_unit_hint': 'e.g. kg, liter, piece',
  'ingredient_form_unit_required': 'Please enter a unit',
  'ingredient_form_current_stock_label': 'Starting stock',
  'ingredient_form_threshold_label': 'Alert when at or below',
  'ingredient_form_current_stock_locked_hint':
      'Use the "Adjust stock" button in the list to change stock later',
  'ingredient_form_submit_edit': 'Save changes',

  // Controller feedback messages
  'ingredient_created_success': 'New ingredient added',
  'ingredient_updated_success': 'Changes saved',
  'ingredient_stock_adjusted_success': 'Stock adjusted',
  'ingredient_delete_title': 'Delete ingredient',
  'ingredient_delete_confirm': 'Delete "@name" from the system?',
  'ingredient_deleted_success': 'Ingredient deleted',

  // Demo store errors
  'ingredient_error_not_found': 'Ingredient not found',
  'ingredient_error_zero_delta': 'Delta must not be zero',
  'ingredient_error_linked_cannot_delete':
      'Cannot delete: this ingredient is linked to a menu item',
  'ingredient_error_duplicate_link':
      'Cannot select the same ingredient twice for one menu item',
  'ingredient_error_link_not_found': 'Selected ingredient not found',
};
