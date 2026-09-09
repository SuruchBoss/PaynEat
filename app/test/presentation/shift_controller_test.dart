import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/shift/domain/entities/shift.dart';
import 'package:payneat_pos/features/shift/domain/repositories/shift_repository.dart';
import 'package:payneat_pos/features/shift/domain/usecases/shift_usecases.dart';
import 'package:payneat_pos/features/shift/presentation/controllers/shift_controller.dart';

class _FakeShiftRepository implements ShiftRepository {
  Result<Shift?> nextCurrentResult = const Result.success(null);
  Result<List<Shift>> nextHistoryResult = const Result.success([]);
  Result<Shift>? nextOpenResult;
  Result<Shift>? nextCloseResult;
  int openCallCount = 0;
  int closeCallCount = 0;

  @override
  Future<Result<Shift?>> getCurrent() async => nextCurrentResult;

  @override
  Future<Result<List<Shift>>> getHistory() async => nextHistoryResult;

  @override
  Future<Result<Shift>> open(double openingCash) async {
    openCallCount++;
    return nextOpenResult!;
  }

  @override
  Future<Result<Shift>> close(
    int id, {
    required double countedCash,
    String? note,
  }) async {
    closeCallCount++;
    return nextCloseResult!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Shift _openShift({double openingCash = 2000}) => Shift(
  id: 1,
  status: ShiftStatus.open,
  openedBy: 1,
  openedByName: 'พี่แอน',
  openedAt: '2026-01-01T00:00:00Z',
  openingCash: openingCash,
);

void main() {
  late _FakeShiftRepository repository;
  late ShiftController controller;

  setUp(() {
    repository = _FakeShiftRepository();
    controller = ShiftController(
      getCurrent: GetCurrentShiftUseCase(repository),
      openShift: OpenShiftUseCase(repository),
      closeShift: CloseShiftUseCase(repository),
      getHistory: GetShiftHistoryUseCase(repository),
    );
  });

  tearDown(() => controller.onClose());

  group('ShiftController', () {
    test('onInit โหลดกะปัจจุบันและประวัติพร้อมกัน', () async {
      repository.nextCurrentResult = Result.success(_openShift());
      repository.nextHistoryResult = Result.success([_openShift()]);

      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.current.value?.id, 1);
      expect(controller.history.length, 1);
      expect(controller.isLoading.value, isFalse);
    });

    test('ไม่มีกะเปิดอยู่ → current เป็น null', () async {
      repository.nextCurrentResult = const Result.success(null);

      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.current.value, isNull);
    });

    test('load ล้มเหลว → ตั้ง errorMessage', () async {
      repository.nextCurrentResult = const Result.failure(
        NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
      );

      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
    });

    // submitOpen/submitClose ทั้งสองผลลัพธ์ (สำเร็จ/ล้มเหลว) แตะ AppDialogs เสมอ
    // จึงไม่ครอบคลุมในเทสต์ระดับ unit นี้ ทดสอบเฉพาะ guard ค่าที่กรอกไม่ถูกต้อง
    // (ดู docs/CODING_STANDARDS.md — รูปแบบเดียวกับ checkout_controller_test.dart)
    test(
      'submitClose เมื่อยังไม่มีกะเปิดอยู่ → คืนทันทีโดยไม่เรียก close use case',
      () async {
        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        await controller.submitClose();

        expect(repository.closeCallCount, 0);
      },
    );

    test('startNewShift เคลียร์ lastClosed', () async {
      repository.nextCurrentResult = const Result.success(null);
      repository.nextCloseResult = Result.success(
        Shift(
          id: 1,
          status: ShiftStatus.closed,
          openedBy: 1,
          openedAt: '2026-01-01T00:00:00Z',
          openingCash: 2000,
          expectedCash: 2500,
          countedCash: 2500,
          variance: 0,
        ),
      );

      controller.onInit();
      await Future<void>.delayed(Duration.zero);
      controller.lastClosed.value = repository.nextCloseResult!.dataOrNull;
      expect(controller.lastClosed.value, isNotNull);

      controller.startNewShift();

      expect(controller.lastClosed.value, isNull);
    });
  });
}
