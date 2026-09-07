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
          error.message,
          statusCode: error.statusCode,
          code: error.code,
          details: details,
        ),
    };
  }

  if (error is CacheException) {
    return UnexpectedFailure(error.message);
  }

  return const UnexpectedFailure();
}

/// helper ลดโค้ด try/catch ซ้ำ ๆ ในทุก repository
Future<Result<T>> guard<T>(Future<T> Function() action) async {
  try {
    return Result.success(await action());
  } catch (error) {
    return Result.failure(mapExceptionToFailure(error));
  }
}
