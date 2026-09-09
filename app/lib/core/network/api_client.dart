import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../../app/config/app_config.dart';
import '../errors/exceptions.dart';

/// HTTP client กลางของแอป
///
/// หน้าที่:
/// - แนบ JWT ให้ทุก request อัตโนมัติ
/// - แกะ envelope `{ success, data, meta }` ของ backend ให้เหลือเฉพาะที่ใช้จริง
/// - แปลง error ทุกแบบให้เป็น [ApiException] / [NetworkException] รูปแบบเดียว
class ApiClient {
  ApiClient({Dio? dio, this.tokenProvider, this.onUnauthorized})
    : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppConfig.apiBaseUrl
      ..connectTimeout = AppConfig.connectTimeout
      ..receiveTimeout = AppConfig.receiveTimeout
      ..headers = {'Content-Type': 'application/json'}
      // ให้ dio ไม่โยน exception เอง เราจัดการ status code ทั้งหมดในที่เดียว
      ..validateStatus = (status) => status != null && status < 500;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = tokenProvider?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    if (AppConfig.enableApiLog) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, request: false),
      );
    }
  }

  final Dio _dio;

  /// ดึง token ปัจจุบัน (ฉีดจากภายนอกเพื่อไม่ให้ network layer ผูกกับ storage)
  final String? Function()? tokenProvider;

  /// ถูกเรียกเมื่อเจอ 401 เพื่อให้แอปเด้งกลับหน้า login
  final void Function()? onUnauthorized;

  Future<ApiResult> get(String path, {Map<String, dynamic>? query}) =>
      _request(() => _dio.get(path, queryParameters: _clean(query)));

  Future<ApiResult> post(String path, {Object? body}) =>
      _request(() => _dio.post(path, data: body));

  Future<ApiResult> patch(String path, {Object? body}) =>
      _request(() => _dio.patch(path, data: body));

  Future<ApiResult> delete(String path) => _request(() => _dio.delete(path));

  Future<ApiResult> _request(Future<Response<dynamic>> Function() send) async {
    late final Response<dynamic> response;
    try {
      response = await send();
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      throw ApiException(
        message: error.message ?? 'error_api_call_failed'.tr,
        statusCode: error.response?.statusCode,
      );
    }

    final statusCode = response.statusCode ?? 500;
    final body = response.data;

    if (statusCode >= 200 && statusCode < 300) {
      if (body is Map<String, dynamic>) {
        return ApiResult(
          data: body['data'],
          meta: body['meta'] as Map<String, dynamic>?,
        );
      }
      return const ApiResult(data: null);
    }

    if (statusCode == 401) onUnauthorized?.call();

    final error = body is Map<String, dynamic> ? body['error'] : null;
    throw ApiException(
      message: error is Map<String, dynamic>
          ? (error['message'] as String? ?? 'error_api_call_failed'.tr)
          : 'error_api_call_failed_with_status'.trParams({
              'status': statusCode.toString(),
            }),
      statusCode: statusCode,
      code: error is Map<String, dynamic> ? error['code'] as String? : null,
      details: error is Map<String, dynamic> && error['details'] is List
          ? (error['details'] as List).whereType<Map<String, dynamic>>().toList(
              growable: false,
            )
          : null,
    );
  }

  /// ตัด key ที่เป็น null ออกจาก query string
  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final cleaned = <String, dynamic>{};
    query.forEach((key, value) {
      if (value != null) cleaned[key] = value;
    });
    return cleaned.isEmpty ? null : cleaned;
  }
}

/// ผลลัพธ์ดิบจาก API หลังแกะ envelope แล้ว
class ApiResult {
  const ApiResult({required this.data, this.meta});

  final dynamic data;
  final Map<String, dynamic>? meta;

  Map<String, dynamic> get asMap => data is Map<String, dynamic>
      ? data as Map<String, dynamic>
      : <String, dynamic>{};

  List<Map<String, dynamic>> get asList => data is List
      ? (data as List).whereType<Map<String, dynamic>>().toList(growable: false)
      : const [];

  int get total => (meta?['total'] as num?)?.toInt() ?? asList.length;
}
