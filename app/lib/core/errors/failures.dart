// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:get/get.dart';

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
    this.requestId,
  });

  final int? statusCode;
  final String? code;

  /// `x-request-id` ของคำขอที่ล้มเหลว — [message] มีรหัสนี้ต่อท้ายอยู่แล้ว (ดู failure_mapper.dart)
  final String? requestId;
}

/// ต่อเน็ตไม่ได้ / timeout
class NetworkFailure extends Failure {
  NetworkFailure([String? message])
    : super(message ?? 'error_network_check_connection'.tr);
}

/// token หมดอายุหรือยังไม่ได้เข้าสู่ระบบ
class UnauthorizedFailure extends Failure {
  UnauthorizedFailure([String? message])
    : super(message ?? 'error_session_expired'.tr);
}

/// สิทธิ์ไม่พอ
class ForbiddenFailure extends Failure {
  ForbiddenFailure([String? message]) : super(message ?? 'error_forbidden'.tr);
}

/// ข้อมูลที่กรอกไม่ผ่านเงื่อนไข
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.details});
}

/// ข้อผิดพลาดที่คาดไม่ถึง
class UnexpectedFailure extends Failure {
  UnexpectedFailure([String? message])
    : super(message ?? 'error_unexpected'.tr);
}
