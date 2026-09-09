/// เว็บไม่มี `dart:io` ให้เปิด TCP socket ตรง ๆ จาก browser — ไฟล์นี้ถูกเลือกใช้แทน
/// `printer_transport_io.dart` เฉพาะตอน build เป็นเว็บ (ดู conditional import ใน
/// `receipt_printer_service.dart`) จริง ๆ แล้วจะไม่ถูกเรียกเพราะ service เช็ก `kIsWeb`
/// และคืนความล้มเหลวไว้ก่อนแล้ว แต่ต้องมีไฟล์นี้ให้เว็บคอมไพล์ผ่าน
Future<void> sendBytes(String ipAddress, int port, List<int> bytes) {
  throw UnsupportedError('ไม่รองรับการเชื่อมต่อเครื่องพิมพ์บนแพลตฟอร์มนี้');
}
