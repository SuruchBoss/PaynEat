import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/customer/domain/entities/customer.dart';
import 'package:payneat_pos/features/customer/domain/repositories/customer_repository.dart';
import 'package:payneat_pos/features/customer/domain/usecases/customer_usecases.dart';
import 'package:payneat_pos/features/customer/presentation/widgets/customer_picker_dialog.dart';

/// repo ปลอมที่นับจำนวนครั้งที่ถูกเรียก และสั่งให้ล้มเหลวเฉพาะครั้งแรกได้
class _FakeCustomerRepository implements CustomerRepository {
  _FakeCustomerRepository({this.failFirstCall = false});

  final bool failFirstCall;
  int searchCalls = 0;

  @override
  Future<Result<({List<Customer> customers, int total})>> search({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    searchCalls++;
    if (failFirstCall && searchCalls == 1) {
      return Result.failure(NetworkFailure('เชื่อมต่อไม่ได้'));
    }
    return Result.success((
      customers: const [
        Customer(
          id: 1,
          name: 'สมหญิง ใจดี',
          phone: '0812345678',
          pointsBalance: 120,
        ),
      ],
      total: 1,
    ));
  }

  @override
  Future<Result<Customer>> getById(int id) async =>
      Result.failure(NetworkFailure('ไม่ได้ใช้ในเทสต์นี้'));

  @override
  Future<Result<Customer>> create({
    required String name,
    required String phone,
    String? email,
  }) async => Result.failure(NetworkFailure('ไม่ได้ใช้ในเทสต์นี้'));

  @override
  Future<Result<Customer>> updateCredit(
    int id,
    CustomerCreditTerms terms,
  ) async => Result.failure(NetworkFailure('ไม่ได้ใช้ในเทสต์นี้'));
}

void main() {
  Future<_FakeCustomerRepository> pumpDialog(
    WidgetTester tester, {
    bool failFirstCall = false,
  }) async {
    final repository = _FakeCustomerRepository(failFirstCall: failFirstCall);
    Get.put<SearchCustomersUseCase>(SearchCustomersUseCase(repository));
    Get.put<CreateCustomerUseCase>(CreateCustomerUseCase(repository));
    addTearDown(Get.reset);

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: CustomerPickerDialog())),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  group('CustomerPickerDialog', () {
    testWidgets('เน็ตสะดุดครั้งเดียวแล้วค้นใหม่สำเร็จ ต้องกลับมาเห็นรายชื่อ '
        '(ไม่ค้างที่หน้า error)', (tester) async {
      await pumpDialog(tester, failFirstCall: true);
      expect(find.text('เชื่อมต่อไม่ได้'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'สมหญิง');
      await tester.pump(const Duration(milliseconds: 400)); // พ้นดีบาวซ์
      await tester.pumpAndSettle();

      expect(find.text('เชื่อมต่อไม่ได้'), findsNothing);
      expect(find.text('สมหญิง ใจดี'), findsOneWidget);
    });

    testWidgets('สถานะ error มีปุ่มลองใหม่ให้กดกู้ได้โดยไม่ต้องพิมพ์', (
      tester,
    ) async {
      final repository = await pumpDialog(tester, failFirstCall: true);
      expect(repository.searchCalls, 1);

      // หาโดยไอคอน ไม่ใช่ข้อความ — ใน GetMaterialApp ของเทสต์ `.tr` คืนคีย์ดิบ
      // (แอปจริงส่ง translations เข้า GetMaterialApp จึงแปลได้ตามปกติ)
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      expect(repository.searchCalls, 2);
      expect(find.text('สมหญิง ใจดี'), findsOneWidget);
    });

    testWidgets('ดีบาวซ์: พิมพ์รัว ๆ 6 ตัวอักษร ต้องยิงค้นหาแค่ครั้งเดียว', (
      tester,
    ) async {
      final repository = await pumpDialog(tester);
      repository.searchCalls = 0; // ไม่นับการโหลดตอนเปิดกล่อง

      const typed = 'สมหญิง';
      for (var i = 1; i <= typed.length; i++) {
        await tester.enterText(
          find.byType(TextField).first,
          typed.substring(0, i),
        );
        await tester.pump(const Duration(milliseconds: 60));
      }
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(
        repository.searchCalls,
        1,
        reason:
            'ไม่มีดีบาวซ์จะยิง ${typed.length} ครั้ง — '
            'กล่องนี้ถูกใช้ตอนรับออเดอร์บนเน็ตร้านที่สะดุดบ่อย',
      );
    });
  });
}
