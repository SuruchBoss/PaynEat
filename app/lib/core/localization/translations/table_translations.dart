/// คำแปลของฟีเจอร์ table
const Map<String, String> tableTranslationsTh = {
  'table_error_not_found': 'ไม่พบโต๊ะนี้',
  'table_error_has_open_order': 'โต๊ะนี้ยังมีออเดอร์ที่ยังไม่ปิด',
  'table_status_updated_success': 'อัปเดตสถานะโต๊ะ @name แล้ว',
  'table_loading_message': 'กำลังโหลดผังโต๊ะ...',
  'table_empty_filtered_message': 'ไม่พบโต๊ะตามเงื่อนไขที่เลือก',
  'table_count_in_zone': '@count โต๊ะ',
  'table_number_label': 'โต๊ะ @name',
  'table_seat_count': '@count ที่นั่ง',
  'table_available_count_label': 'โต๊ะว่าง',
  'table_occupied_count_label': 'มีลูกค้า',
  'table_refresh_tooltip': 'รีเฟรช',
  'table_all_zones_filter': 'ทุกโซน',
  'table_new_takeaway_delivery_button': 'สั่งกลับบ้าน/เดลิเวอรี่',
  // ดู docs/tickets/17-qr-self-order.md
  'table_qr_action_label': 'ดู QR สั่งอาหารเอง',
  'table_qr_sheet_title': 'QR สั่งอาหาร — โต๊ะ @name',
  'table_qr_missing_message':
      'โต๊ะนี้ยังไม่มี QR token (ข้อมูลเก่าก่อนอัปเดต) โหลดหน้านี้ใหม่อีกครั้ง',
  'table_qr_scan_instruction':
      'ให้ลูกค้าสแกนด้วยกล้องมือถือเพื่อสั่งอาหารเองที่โต๊ะนี้',
  'table_qr_semantics': 'QR สั่งอาหารเองของโต๊ะ @name',
  'table_qr_copy_link_button': 'คัดลอกลิงก์',
  'table_qr_link_copied': 'คัดลอกลิงก์แล้ว',
  'table_qr_regenerate_button': 'เปลี่ยน QR',
  'table_qr_regenerate_confirm_title': 'เปลี่ยน QR โต๊ะนี้?',
  'table_qr_regenerate_confirm_message':
      'QR เดิมที่พิมพ์/แปะไว้ที่โต๊ะ @name จะใช้สั่งอาหารไม่ได้อีกทันที ต้องพิมพ์ QR ใหม่ไปติดแทน',
  'table_qr_regenerate_success': 'เปลี่ยน QR โต๊ะแล้ว',
};

const Map<String, String> tableTranslationsEn = {
  'table_error_not_found': 'Table not found',
  'table_error_has_open_order': 'This table still has an unpaid order',
  'table_status_updated_success': 'Table @name status updated',
  'table_loading_message': 'Loading floor plan...',
  'table_empty_filtered_message': 'No tables match the selected filters',
  'table_count_in_zone': '@count tables',
  'table_number_label': 'Table @name',
  'table_seat_count': '@count seats',
  'table_available_count_label': 'Available',
  'table_occupied_count_label': 'Occupied',
  'table_refresh_tooltip': 'Refresh',
  'table_all_zones_filter': 'All zones',
  'table_new_takeaway_delivery_button': 'New takeaway/delivery',
  // ดู docs/tickets/17-qr-self-order.md
  'table_qr_action_label': 'View self-order QR',
  'table_qr_sheet_title': 'Self-order QR — Table @name',
  'table_qr_missing_message':
      'This table has no QR token yet (legacy data). Reload this page.',
  'table_qr_scan_instruction':
      'Have the customer scan with their phone camera to order for this table.',
  'table_qr_semantics': 'Self-order QR for table @name',
  'table_qr_copy_link_button': 'Copy link',
  'table_qr_link_copied': 'Link copied',
  'table_qr_regenerate_button': 'Regenerate QR',
  'table_qr_regenerate_confirm_title': 'Regenerate this table\'s QR?',
  'table_qr_regenerate_confirm_message':
      'The QR code printed at table @name will stop working immediately. Print and place the new one.',
  'table_qr_regenerate_success': 'Table QR regenerated',
};
