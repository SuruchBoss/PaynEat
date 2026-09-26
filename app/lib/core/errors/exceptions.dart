// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:get/get.dart';

/// Exception ระดับ data layer — ถูกแปลงเป็น [Failure] ที่ชั้น repository
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
    this.requestId,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final List<Map<String, dynamic>>? details;

  /// `x-request-id` ของคำขอนี้ — รหัสเดียวกับใน log ของ backend (สัญญา telemetry, ticket 24)
  final String? requestId;

  @override
  String toString() => 'ApiException($statusCode, $code, $requestId): $message';
}

class NetworkException implements Exception {
  const NetworkException([this._message]);

  final String? _message;
  String get message => _message ?? 'error_network_unreachable'.tr;

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  const CacheException([this._message]);

  final String? _message;
  String get message => _message ?? 'error_cache_io'.tr;
}
