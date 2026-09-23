import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/network/api_client.dart';

/// ตอบทุก request ด้วยไบต์ที่กำหนดไว้ — แทน backend จริงเพื่อคุมว่า "ไบต์ที่ส่งมา" คืออะไรพอดี
class _FixedBytesAdapter implements HttpClientAdapter {
  _FixedBytesAdapter(this.bytes);

  final List<int> bytes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromBytes(
    bytes,
    200,
    headers: {
      Headers.contentTypeHeader: ['text/csv; charset=utf-8'],
    },
  );

  @override
  void close({bool force = false}) {}
}

ApiClient _clientReturning(List<int> bytes) {
  final dio = Dio()..httpClientAdapter = _FixedBytesAdapter(bytes);
  final client = ApiClient(dio: dio);
  dio.interceptors.removeWhere((interceptor) => interceptor is LogInterceptor);
  return client;
}

void main() {
  const bomBytes = [0xEF, 0xBB, 0xBF];
  const csvBody = 'รายการ,ยอด (บาท)\r\nยอดขายสุทธิ,323.68';

  group('ApiClient.getText — ไฟล์ CSV ต้องออกมาตรงกับที่ backend ส่งทุกไบต์', () {
    // backend ใส่ UTF-8 BOM หัวไฟล์ CSV ทุกไฟล์ (backend/src/core/csv.js) ให้ Excel อ่านภาษาไทยถูก
    // แต่ตัวถอด UTF-8 ของ Dart ตัด BOM หัวข้อความทิ้งเสมอ — ถ้า getText ถอดแบบปกติ ไฟล์ที่ร้าน
    // ดาวน์โหลดไปจะไม่มี BOM แล้วเปิดใน Excel เป็นตัวอักษรเพี้ยน ทั้งที่โหมดสาธิตดูปกติทุกอย่าง
    // (โหมดสาธิตสร้าง CSV ฝั่ง Dart เองพร้อม BOM ไม่ผ่าน getText) — เจอจากชุด E2E ใน test_e2e/
    test('คง BOM ไว้เมื่อ backend ส่งมา', () async {
      final text = await _clientReturning([
        ...bomBytes,
        ...utf8.encode(csvBody),
      ]).getText('/reports/export/summary');

      expect(text.startsWith('\uFEFF'), isTrue);
      expect(text.substring(1), csvBody);
    });

    test('ไม่เติม BOM เองถ้า backend ไม่ได้ส่งมา', () async {
      final text = await _clientReturning(
        utf8.encode(csvBody),
      ).getText('/reports/export/summary');

      expect(text, csvBody);
    });

    test('ไฟล์ว่างได้ข้อความว่าง ไม่พัง', () async {
      final text = await _clientReturning(
        const [],
      ).getText('/reports/export/summary');

      expect(text, isEmpty);
    });
  });
}
