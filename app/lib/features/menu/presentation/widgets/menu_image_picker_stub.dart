/// การเลือกรูปเมนูรองรับเฉพาะหน้าเว็บแอดมิน (ตามที่ตั้งใจไว้) — ไฟล์นี้ถูกเลือกใช้แทน
/// `menu_image_picker_web.dart` บนแพลตฟอร์มที่ไม่มี `dart:html` (Android/iOS/desktop)
/// จริง ๆ แล้วจะไม่ถูกเรียกเพราะ `menu_form_page.dart` เช็ก `kIsWeb` และซ่อนปุ่มเลือกรูปไว้ก่อนแล้ว
/// แต่ต้องมีไฟล์นี้ให้แพลตฟอร์มอื่นคอมไพล์ผ่าน (ดู conditional import ที่เลือกไฟล์นี้)
Future<({String dataUrl, int sizeBytes})?> pickMenuImage() {
  throw UnsupportedError('เลือกรูปเมนูได้เฉพาะบนหน้าเว็บแอดมินเท่านั้น');
}
