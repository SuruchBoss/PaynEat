// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/network/api_client.dart';
import 'package:payneat_pos/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:payneat_pos/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:payneat_pos/features/customer/domain/usecases/customer_usecases.dart';
import 'package:payneat_pos/features/customer/presentation/controllers/customers_controller.dart';

/// backend จำลอง: จดทุก request ที่ออกจากเครื่องจริง (หลังผ่าน interceptor แล้ว) และตอบ error ตามที่ตั้งไว้
/// พร้อมส่ง `x-request-id` เดิมกลับมาเหมือน backend จริง (backend/src/middlewares/requestContext.js)
class _ErrorBackend implements HttpClientAdapter {
  _ErrorBackend(this.status, this.error);

  final int status;
  final Map<String, dynamic> error;
  final sentIds = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final id = options.headers[ApiClient.requestIdHeader] as String;
    sentIds.add(id);
    return ResponseBody.fromBytes(
      utf8.encode(
        jsonEncode({
          'success': false,
          'error': {...error, 'requestId': id},
        }),
      ),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
        ApiClient.requestIdHeader: [id],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

CustomersController _controllerOver(_ErrorBackend backend) {
  final dio = Dio()..httpClientAdapter = backend;
  final client = ApiClient(dio: dio);
  dio.interceptors.removeWhere((interceptor) => interceptor is LogInterceptor);
  return CustomersController(
    searchCustomers: SearchCustomersUseCase(
      CustomerRepositoryImpl(CustomerRemoteDataSourceImpl(client)),
    ),
  );
}

void main() {
  // ร้านแจ้งปัญหาพร้อมรหัสคำขอที่เห็นบนจอ แล้วค้น log ของ backend ด้วยรหัสนั้นได้ตรงตัว (ticket 24 — สัญญา
  // telemetry v1.1) เดินผ่านของจริงทั้งสาย: ApiClient → data source → repository (guard) → use case → controller
  group('รหัสคำขอ (x-request-id) บนข้อความ error', () {
    test(
      '500: ข้อความที่ backend แปลแล้ว + รหัสคำขอเดียวกับที่ส่งไปและอยู่ใน log ของ backend',
      () async {
        final backend = _ErrorBackend(500, {
          'code': 'INTERNAL_ERROR',
          'message': 'เกิดข้อผิดพลาดภายในระบบ',
        });
        final controller = _controllerOver(backend);

        await controller.load();

        final sent = backend.sentIds.single;
        expect(
          controller.errorMessage.value,
          'เกิดข้อผิดพลาดภายในระบบ\nรหัสคำขอ: $sent',
        );
      },
    );

    test('409 ที่เซิร์ฟเวอร์ปฏิเสธ: มีรหัสคำขอต่อท้ายด้วย', () async {
      final backend = _ErrorBackend(409, {
        'code': 'CONFLICT',
        'message': 'เบอร์โทรนี้มีสมาชิกอยู่แล้ว',
      });
      final controller = _controllerOver(backend);

      await controller.load();

      expect(
        controller.errorMessage.value,
        endsWith('รหัสคำขอ: ${backend.sentIds.single}'),
      );
    });

    test(
      '422 ข้อมูลกรอกไม่ผ่าน: ไม่ต่อรหัส (แสดงใต้ช่องกรอก ไม่ใช่ปัญหาที่ต้องแจ้งใคร)',
      () async {
        final controller = _controllerOver(
          _ErrorBackend(422, {
            'code': 'UNPROCESSABLE_ENTITY',
            'message': 'ข้อมูลที่ส่งมาไม่ถูกต้อง',
          }),
        );

        await controller.load();

        expect(controller.errorMessage.value, 'ข้อมูลที่ส่งมาไม่ถูกต้อง');
      },
    );
  });

  test(
    'ทุก request ได้ x-request-id ใหม่ที่ backend รับได้ (^[\\w-]{8,64}\$) ไม่ซ้ำกัน',
    () async {
      final backend = _ErrorBackend(409, {'code': 'CONFLICT', 'message': 'x'});
      final controller = _controllerOver(backend);

      await controller.load();
      await controller.load();

      expect(backend.sentIds, hasLength(2));
      for (final id in backend.sentIds) {
        expect(id, matches(RegExp(r'^pos-[0-9a-f]{16}$')));
      }
      expect(backend.sentIds.toSet(), hasLength(2));
    },
  );

  test('ServerFailure เก็บรหัสคำขอไว้แยกให้โค้ดอ่านได้ด้วย', () async {
    final backend = _ErrorBackend(500, {
      'code': 'INTERNAL_ERROR',
      'message': 'เกิดข้อผิดพลาดภายในระบบ',
    });
    final dio = Dio()..httpClientAdapter = backend;
    final client = ApiClient(dio: dio);
    dio.interceptors.removeWhere(
      (interceptor) => interceptor is LogInterceptor,
    );
    final repository = CustomerRepositoryImpl(
      CustomerRemoteDataSourceImpl(client),
    );

    final result = await repository.search();

    result.fold(
      onSuccess: (_) => fail('ต้องล้มเหลว'),
      onFailure: (failure) {
        expect(failure, isA<ServerFailure>());
        expect((failure as ServerFailure).requestId, backend.sentIds.single);
        expect(failure.statusCode, 500);
        expect(failure.code, 'INTERNAL_ERROR');
      },
    );
  });
}
