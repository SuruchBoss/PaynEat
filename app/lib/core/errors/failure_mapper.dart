import 'package:get/get.dart';

import '../usecases/result.dart';
import 'exceptions.dart';
import 'failures.dart';

/// แปลง exception จากชั้น data → Failure ที่ชั้น domain/presentation เข้าใจ
/// รวมไว้ที่เดียวเพื่อให้ทุก repository จัดการ error เหมือนกัน
Failure mapExceptionToFailure(Object error) {
  if (error is NetworkException) {
    return NetworkFailure(error.message);
  }

  if (error is ApiException) {
    final details = error.details
        ?.map(
          (item) => FieldError(
            field: item['field'] as String? ?? '',
            message: item['message'] as String? ?? '',
          ),
        )
        .toList(growable: false);

    return switch (error.statusCode) {
      401 => UnauthorizedFailure(error.message),
      403 => ForbiddenFailure(error.message),
      422 => ValidationFailure(error.message, details: details),
      _ => ServerFailure(
        withRequestId(error.message, error.requestId),
        statusCode: error.statusCode,
        code: error.code,
        details: details,
        requestId: error.requestId,
      ),
    };
  }

  if (error is CacheException) {
    return UnexpectedFailure(error.message);
  }

  return UnexpectedFailure();
}

/// ต่อรหัสคำขอท้ายข้อความ error ที่เซิร์ฟเวอร์ปฏิเสธหรือทำไม่สำเร็จ — ร้านแจ้งรหัสนี้แล้วค้น log ของ backend
/// ได้ตรงตัว (สัญญา telemetry, ticket 24) ไม่ต่อกับ 401/403/422 ซึ่งแอปมีทางจัดการเฉพาะอยู่แล้ว (เด้งไปหน้า
/// login, ข้อความสิทธิ์ไม่พอ, error ใต้ช่องกรอก) และไม่ใช่ปัญหาที่ต้องแจ้งใคร
String withRequestId(String message, String? requestId) => requestId == null
    ? message
    : '$message\n${'error_request_id'.trParams({'id': requestId})}';

/// helper ลดโค้ด try/catch ซ้ำ ๆ ในทุก repository
Future<Result<T>> guard<T>(Future<T> Function() action) async {
  try {
    return Result.success(await action());
  } catch (error) {
    return Result.failure(mapExceptionToFailure(error));
  }
}
