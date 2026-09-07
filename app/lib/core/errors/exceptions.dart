/// Exception ระดับ data layer — ถูกแปลงเป็น [Failure] ที่ชั้น repository
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final List<Map<String, dynamic>>? details;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  const CacheException([this.message = 'อ่าน/เขียนข้อมูลในเครื่องไม่สำเร็จ']);

  final String message;
}
