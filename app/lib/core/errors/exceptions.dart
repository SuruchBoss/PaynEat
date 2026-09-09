import 'package:get/get.dart';

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
