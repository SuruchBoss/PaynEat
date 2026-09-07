import '../errors/failures.dart';
import 'result.dart';

/// สัญญาของ use case ทุกตัวในระบบ
/// เรียกใช้แบบ `await useCase(params)` ได้เลยเพราะ override `call`
abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// use case ที่ไม่ต้องรับพารามิเตอร์
abstract class NoParamsUseCase<T> {
  Future<Result<T>> call();
}

/// ใช้แทนพารามิเตอร์ว่าง
class NoParams {
  const NoParams();
}

/// helper ให้ repository ห่อการเรียก data source แล้วแปลง exception เป็น Failure
typedef FailureMapper = Failure Function(Object error, StackTrace stackTrace);
