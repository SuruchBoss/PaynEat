import '../../../core/errors/failures.dart';

/// ลิงก์ QR นี้ใช้ไม่ได้แล้ว (ลองใหม่ก็ไม่มีวันสำเร็จ) หรือแค่เน็ตสะดุด (ลองใหม่ได้)
///
/// - 404: token ไม่มีจริง / โต๊ะถูกปิดใช้งาน / ผู้จัดการสร้าง QR ใหม่ไปแล้ว
/// - [ValidationFailure] (400): รูปแบบ token ผิดตั้งแต่ต้น เช่น ลิงก์ถูกตัดท้ายตอนส่งต่อทาง LINE —
///   backend บังคับให้ token เป็น UUID (`public-order.schema.js`) และ input เดียวของคำขอนี้คือ token
///   จาก URL validation ไม่ผ่านจึงแปลว่าลิงก์เสียเท่านั้น
///
/// ที่เหลือ (เน็ตหลุด/timeout/500) ยังให้ลูกค้ากดลองใหม่ได้ — เดิมนับแค่ 404 ลิงก์ที่ถูกตัดท้ายจึงขึ้น
/// หน้า "ไม่มีอินเทอร์เน็ต" พร้อมปุ่มลองใหม่ที่ไม่มีวันสำเร็จ (เจอจากชุด E2E ใน `test_e2e/`)
bool isBrokenSelfOrderLink(Failure failure) =>
    failure is ValidationFailure ||
    (failure is ServerFailure && failure.statusCode == 404);
