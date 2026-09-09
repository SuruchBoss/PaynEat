import 'dart:async';
import 'dart:html' as html;

/// เปิด file picker ของเบราว์เซอร์ให้เลือกรูปเมนู แล้วอ่านออกมาเป็น data URL
/// (base64) ตรง ๆ ในเครื่อง — ไม่ต้องมี endpoint อัปโหลดไฟล์แยกฝั่ง backend
/// เพราะ `menu_items.image_url` เก็บเป็น string ยาวได้อยู่แล้ว
///
/// คืนค่า null ถ้าผู้ใช้ปิดหน้าต่างเลือกไฟล์โดยไม่เลือกอะไร (แยกฟังทั้ง `change` และ
/// `cancel` เพราะแค่ฟัง `change` อย่างเดียว ตอนกดยกเลิกจะไม่มี event ยิงออกมาเลย
/// ทำให้ Future ค้างรอตลอดไป)
Future<({String dataUrl, int sizeBytes})?> pickMenuImage() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  final fileCompleter = Completer<html.File?>();

  input.onChange.first.then((_) {
    if (fileCompleter.isCompleted) return;
    final files = input.files;
    fileCompleter.complete(files != null && files.isNotEmpty ? files.first : null);
  });
  input.on['cancel'].first.then((_) {
    if (!fileCompleter.isCompleted) fileCompleter.complete(null);
  });

  input.click();
  final file = await fileCompleter.future;
  if (file == null) return null;

  final reader = html.FileReader();
  reader.readAsDataUrl(file);
  await reader.onLoad.first;

  return (dataUrl: reader.result as String, sizeBytes: file.size);
}
