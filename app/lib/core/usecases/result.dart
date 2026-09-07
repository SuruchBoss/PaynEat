import '../errors/failures.dart';

/// ผลลัพธ์ที่ "สำเร็จหรือล้มเหลว" อย่างชัดเจน แทนการโยน exception ข้ามชั้น
/// (แนวคิดเดียวกับ `Either<Failure, T>` แต่เขียนเองเพื่อไม่ต้องพึ่ง dartz)
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  T? get dataOrNull => switch (this) {
    Success<T>(:final data) => data,
    FailureResult<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    FailureResult<T>(:final failure) => failure,
  };

  /// แตกผลลัพธ์ออกเป็นสองทางแบบบังคับให้จัดการครบทั้งคู่
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) => switch (this) {
    Success<T>(:final data) => onSuccess(data),
    FailureResult<T>(:final failure) => onFailure(failure),
  };

  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success<T>(:final data) => Result<R>.success(transform(data)),
    FailureResult<T>(:final failure) => Result<R>.failure(failure),
  };
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final Failure failure;
}
