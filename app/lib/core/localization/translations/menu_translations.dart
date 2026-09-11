/// คำแปลของฟีเจอร์ menu
const Map<String, String> menuTranslationsTh = {
  // Management page — search / filter bar / list header
  'menu_search_hint': 'ค้นหาเมนู...',
  'menu_category_button': 'หมวดหมู่',
  'menu_total_count': 'ทั้งหมด @count เมนู',
  'menu_unavailable_count': 'ปิดขายอยู่ @count',
  'menu_empty_category': 'ยังไม่มีเมนูในหมวดนี้',
  'menu_option_groups_count': '@count กลุ่มตัวเลือก',
  'menu_add_item_button': 'เพิ่มเมนู',

  // Category management sheet / dialog
  'menu_manage_categories_title': 'จัดการหมวดหมู่',
  'menu_category_item_count': '@count เมนู',
  'menu_add_category_title': 'เพิ่มหมวดหมู่',
  'menu_edit_category_title': 'แก้ไขหมวดหมู่',
  'menu_category_name_label': 'ชื่อหมวดหมู่',
  'menu_category_icon_label': 'ไอคอน (อีโมจิ)',

  // Menu item form
  'menu_form_add_title': 'เพิ่มเมนูใหม่',
  'menu_form_edit_title': 'แก้ไขเมนู',
  'menu_form_info_section': 'ข้อมูลเมนู',
  'menu_form_photo_label': 'รูปเมนู',
  'menu_form_photo_pick': 'เลือกรูปภาพ',
  'menu_form_photo_change': 'เปลี่ยนรูปภาพ',
  'menu_form_photo_remove': 'ลบรูป',
  'menu_form_photo_hint': 'ระบบย่อรูปให้อัตโนมัติ — ไม่มีรูปก็ใช้งานได้ตามปกติ',
  'menu_form_photo_source_camera': 'ถ่ายรูปตอนนี้',
  'menu_form_photo_source_gallery': 'เลือกจากคลังภาพ',
  'menu_form_photo_too_large': 'รูปนี้ใหญ่เกินไปแม้ย่อแล้ว กรุณาเลือกรูปอื่น',
  'menu_form_photo_pick_failed': 'เลือกรูปไม่สำเร็จ กรุณาลองอีกครั้ง',
  'menu_form_name_label': 'ชื่อเมนู *',
  'menu_form_name_required': 'กรุณากรอกชื่อเมนู',
  'menu_form_name_en_label': 'ชื่อภาษาอังกฤษ',
  'menu_form_category_label': 'หมวดหมู่ *',
  'menu_form_category_required': 'กรุณาเลือกหมวดหมู่',
  'menu_form_price_label': 'ราคา *',
  'menu_form_price_invalid': 'กรุณากรอกราคาให้ถูกต้อง',
  'menu_form_prep_time_label': 'เวลาทำ',
  'menu_form_minutes_suffix': 'นาที',
  'menu_form_description_label': 'คำอธิบาย',
  'menu_form_available_label': 'เปิดขาย',
  'menu_form_recommended_label': 'เมนูแนะนำ',
  'menu_form_recommended_subtitle': 'จะมีป้ายดาวบนจอสั่งอาหาร',
  'menu_form_option_groups_section': 'กลุ่มตัวเลือก',
  'menu_form_option_groups_hint': 'เช่น ระดับความเผ็ด, เพิ่มไข่ดาว',
  'menu_form_add_group_button': 'เพิ่มกลุ่ม',
  'menu_form_no_option_groups': 'ยังไม่มีกลุ่มตัวเลือก',
  'menu_form_submit_edit': 'บันทึกการแก้ไข',

  // Option group dialog
  'menu_option_required_badge': 'ต้องเลือก',
  'menu_option_max_select_badge': 'เลือกได้ @count',
  'menu_option_group_dialog_title': 'เพิ่มกลุ่มตัวเลือก',
  'menu_option_group_name_label': 'ชื่อกลุ่ม',
  'menu_option_group_name_hint': 'เช่น ระดับความเผ็ด',
  'menu_option_max_select_label': 'เลือกได้',
  'menu_option_name_label': 'ตัวเลือก',
  'menu_option_price_delta_label': '+บาท',

  // Item card badges
  'menu_recommended_badge': 'แนะนำ',
  'menu_sold_out_badge': 'ของหมด',

  // Controller feedback messages
  'menu_mark_available_success': 'เปิดขาย "@name" แล้ว',
  'menu_mark_unavailable_success': 'ปิดขาย "@name" แล้ว',
  'menu_item_created_success': 'เพิ่มเมนูใหม่แล้ว',
  'menu_item_updated_success': 'บันทึกการแก้ไขแล้ว',
  'menu_delete_item_title': 'ลบเมนู',
  'menu_delete_item_confirm': 'ต้องการลบ "@name" ออกจากระบบใช่หรือไม่?',
  'menu_item_deleted_success': 'ลบเมนูแล้ว',
  'menu_category_created_success': 'เพิ่มหมวดหมู่แล้ว',
  'menu_category_updated_success': 'แก้ไขหมวดหมู่แล้ว',
  'menu_delete_category_title': 'ลบหมวดหมู่',
  'menu_delete_category_confirm': 'ต้องการลบหมวดหมู่ "@name" ใช่หรือไม่?',
  'menu_category_deleted_success': 'ลบหมวดหมู่แล้ว',

  // Demo store errors
  'menu_delete_category_has_items_error':
      'ลบไม่ได้ เพราะยังมีเมนูอยู่ในหมวดหมู่นี้',
  'menu_item_not_found_error': 'ไม่พบเมนูนี้',
};

const Map<String, String> menuTranslationsEn = {
  // Management page — search / filter bar / list header
  'menu_search_hint': 'Search menu...',
  'menu_category_button': 'Category',
  'menu_total_count': '@count items total',
  'menu_unavailable_count': '@count unavailable',
  'menu_empty_category': 'No menu items in this category yet',
  'menu_option_groups_count': '@count option groups',
  'menu_add_item_button': 'Add menu item',

  // Category management sheet / dialog
  'menu_manage_categories_title': 'Manage categories',
  'menu_category_item_count': '@count items',
  'menu_add_category_title': 'Add category',
  'menu_edit_category_title': 'Edit category',
  'menu_category_name_label': 'Category name',
  'menu_category_icon_label': 'Icon (emoji)',

  // Menu item form
  'menu_form_add_title': 'Add new menu item',
  'menu_form_edit_title': 'Edit menu item',
  'menu_form_info_section': 'Menu information',
  'menu_form_photo_label': 'Photo',
  'menu_form_photo_pick': 'Choose photo',
  'menu_form_photo_change': 'Change photo',
  'menu_form_photo_remove': 'Remove photo',
  'menu_form_photo_hint':
      'Images are resized automatically — a photo is optional',
  'menu_form_photo_source_camera': 'Take a photo',
  'menu_form_photo_source_gallery': 'Choose from library',
  'menu_form_photo_too_large':
      'That image is still too large after resizing — please pick another',
  'menu_form_photo_pick_failed': 'Could not pick that image, please try again',
  'menu_form_name_label': 'Menu name *',
  'menu_form_name_required': 'Please enter a menu name',
  'menu_form_name_en_label': 'English name',
  'menu_form_category_label': 'Category *',
  'menu_form_category_required': 'Please select a category',
  'menu_form_price_label': 'Price *',
  'menu_form_price_invalid': 'Please enter a valid price',
  'menu_form_prep_time_label': 'Prep time',
  'menu_form_minutes_suffix': 'min',
  'menu_form_description_label': 'Description',
  'menu_form_available_label': 'Available for sale',
  'menu_form_recommended_label': 'Recommended item',
  'menu_form_recommended_subtitle': 'Shows a star badge on the ordering screen',
  'menu_form_option_groups_section': 'Option groups',
  'menu_form_option_groups_hint': 'e.g. spice level, add fried egg',
  'menu_form_add_group_button': 'Add group',
  'menu_form_no_option_groups': 'No option groups yet',
  'menu_form_submit_edit': 'Save changes',

  // Option group dialog
  'menu_option_required_badge': 'Required',
  'menu_option_max_select_badge': 'Choose up to @count',
  'menu_option_group_dialog_title': 'Add option group',
  'menu_option_group_name_label': 'Group name',
  'menu_option_group_name_hint': 'e.g. spice level',
  'menu_option_max_select_label': 'Max select',
  'menu_option_name_label': 'Option',
  'menu_option_price_delta_label': '+THB',

  // Item card badges
  'menu_recommended_badge': 'Recommended',
  'menu_sold_out_badge': 'Sold out',

  // Controller feedback messages
  'menu_mark_available_success': 'Marked "@name" as available',
  'menu_mark_unavailable_success': 'Marked "@name" as unavailable',
  'menu_item_created_success': 'New menu item added',
  'menu_item_updated_success': 'Changes saved',
  'menu_delete_item_title': 'Delete menu item',
  'menu_delete_item_confirm': 'Delete "@name" from the system?',
  'menu_item_deleted_success': 'Menu item deleted',
  'menu_category_created_success': 'Category added',
  'menu_category_updated_success': 'Category updated',
  'menu_delete_category_title': 'Delete category',
  'menu_delete_category_confirm': 'Delete category "@name"?',
  'menu_category_deleted_success': 'Category deleted',

  // Demo store errors
  'menu_delete_category_has_items_error':
      'Cannot delete: this category still has menu items',
  'menu_item_not_found_error': 'Menu item not found',
};
