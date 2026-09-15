import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/audit_log/domain/entities/audit_log.dart';
import 'package:payneat_pos/features/audit_log/domain/repositories/audit_log_repository.dart';
import 'package:payneat_pos/features/audit_log/domain/usecases/audit_log_usecases.dart';
import 'package:payneat_pos/features/audit_log/presentation/controllers/audit_log_controller.dart';

AuditLog _log({int id = 1, String action = 'order.create'}) => AuditLog(
  id: id,
  actorName: 'ผู้ดูแลระบบ',
  action: action,
  entityType: 'order',
  summary: 'ทดสอบ',
  createdAt: '2026-09-15T10:00:00Z',
);

class _ListCall {
  const _ListCall({
    this.actorUserId,
    this.action,
    this.entityType,
    this.dateFrom,
    this.dateTo,
    required this.page,
    required this.limit,
  });

  final int? actorUserId;
  final String? action;
  final String? entityType;
  final String? dateFrom;
  final String? dateTo;
  final int page;
  final int limit;
}

class _FakeAuditLogRepository implements AuditLogRepository {
  Result<({List<AuditLog> logs, int total})> nextListResult = Result.success((
    logs: <AuditLog>[_log()],
    total: 1,
  ));
  Result<String> nextExportResult = const Result.success('csv');
  _ListCall? lastListCall;

  @override
  Future<Result<({List<AuditLog> logs, int total})>> list({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 50,
  }) async {
    lastListCall = _ListCall(
      actorUserId: actorUserId,
      action: action,
      entityType: entityType,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
      limit: limit,
    );
    return nextListResult;
  }

  @override
  Future<Result<String>> exportCsv({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
  }) async => nextExportResult;
}

void main() {
  late _FakeAuditLogRepository repository;
  late AuditLogController controller;

  setUp(() {
    repository = _FakeAuditLogRepository();
    controller = AuditLogController(
      getAuditLogs: GetAuditLogsUseCase(repository),
      exportAuditLogs: ExportAuditLogsUseCase(repository),
    );
  });

  // exportCsv() บนแพลตฟอร์มที่ไม่ใช่เว็บ (รวมถึง test runner) เรียก AppDialogs.error
  // ตรงๆ ทันทีโดยไม่มี guard อื่นให้ทดสอบได้เลยโดยไม่มี GetMaterialApp ที่ pump จริง
  // (ดู docs/CODING_STANDARDS.md หัวข้อ 6.2) — ทดสอบเฉพาะ load/loadMore/setDateRange/
  // filterByAction ที่เป็นตรรกะ/state ล้วนๆ

  group('AuditLogController', () {
    test('load ส่ง filter เริ่มต้นถูกต้อง (ไม่มี action/ช่วงวันที่)', () async {
      await controller.load();

      final call = repository.lastListCall!;
      expect(call.action, isNull);
      expect(call.dateFrom, isNull);
      expect(call.dateTo, isNull);
      expect(call.page, 1);
      expect(call.limit, AuditLogController.pageSize);
      expect(controller.logs.length, 1);
      expect(controller.total.value, 1);
      expect(controller.isLoading.value, isFalse);
    });

    test('load ล้มเหลว → ตั้ง errorMessage', () async {
      repository.nextListResult = Result.failure(
        NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
      );

      await controller.load();

      expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
    });

    test(
      'filterByAction ส่ง action ที่เลือกไปกับ filter และโหลดใหม่',
      () async {
        controller.filterByAction('promotion.create');
        await Future<void>.delayed(Duration.zero);

        expect(controller.actionFilter.value, 'promotion.create');
        expect(repository.lastListCall!.action, 'promotion.create');
      },
    );

    test(
      'setDateRange ตั้งค่าช่วงวันที่ แปลงเป็น ISO date ส่งไปกับ filter และโหลดใหม่',
      () async {
        controller.setDateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
        await Future<void>.delayed(Duration.zero);

        expect(controller.dateFrom.value, DateTime(2026, 3, 1));
        expect(controller.dateTo.value, DateTime(2026, 3, 31));
        expect(repository.lastListCall!.dateFrom, '2026-03-01');
        expect(repository.lastListCall!.dateTo, '2026-03-31');
      },
    );

    test(
      'setDateRange(null, null) ล้างช่วงวันที่แล้วโหลดใหม่โดยไม่มี filter วันที่',
      () async {
        controller.setDateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
        await Future<void>.delayed(Duration.zero);

        controller.setDateRange(null, null);
        await Future<void>.delayed(Duration.zero);

        expect(controller.dateFrom.value, isNull);
        expect(controller.dateTo.value, isNull);
        expect(repository.lastListCall!.dateFrom, isNull);
        expect(repository.lastListCall!.dateTo, isNull);
      },
    );

    test('loadMore ส่งเลขหน้าถัดไปพร้อม filter เดิม และต่อท้ายรายการ', () async {
      // total ต้องมากกว่าจำนวนที่โหลดมาแล้ว ไม่งั้น hasMore เป็น false แล้ว loadMore
      // จะ guard ออกก่อนเรียก repository เลย
      repository.nextListResult = Result.success((
        logs: <AuditLog>[_log()],
        total: 2,
      ));
      controller.setDateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
      await Future<void>.delayed(Duration.zero);

      repository.nextListResult = Result.success((
        logs: <AuditLog>[_log(id: 2)],
        total: 2,
      ));
      await controller.loadMore();

      expect(repository.lastListCall!.page, 2);
      expect(repository.lastListCall!.dateFrom, '2026-03-01');
      expect(controller.logs.length, 2);
      expect(controller.total.value, 2);
    });

    test('hasMore เป็น true เมื่อยังโหลดไม่ครบตาม total', () async {
      repository.nextListResult = Result.success((
        logs: <AuditLog>[_log()],
        total: 5,
      ));
      await controller.load();

      expect(controller.hasMore, isTrue);
    });
  });
}
