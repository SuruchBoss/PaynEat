/// ความล้มเหลวระดับ domain — ชั้น presentation ใช้ตัวนี้เท่านั้น
/// ไม่ต้องรู้จัก DioException หรือรายละเอียดของ data layer
sealed class Failure {
  const Failure(this.message, {this.details});

  final String message;
  final List<FieldError>? details;

  @override
  String toString() => message;
}

class FieldError {
  const FieldError({required this.field, required this.message});

  final String field;
  final String message;
}

/// เซิร์ฟเวอร์ตอบกลับมาเป็น error (4xx / 5xx)
class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    this.statusCode,
    super.details,
    this.code,
  });

  final int? statusCode;
  final String? code;
}

/// ต่อเน็ตไม่ได้ / timeout
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต',
  ]);
}

/// token หมดอายุหรือยังไม่ได้เข้าสู่ระบบ
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',
  ]);
}

/// สิทธิ์ไม่พอ
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'บัญชีนี้ไม่มีสิทธิ์ทำรายการนี้']);
}

/// ข้อมูลที่กรอกไม่ผ่านเงื่อนไข
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.details});
}

/// ข้อผิดพลาดที่คาดไม่ถึง
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'เกิดข้อผิดพลาดที่ไม่คาดคิด']);
}
