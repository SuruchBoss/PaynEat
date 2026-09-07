import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/network/socket_client.dart';
import 'package:payneat_pos/core/services/session_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/table/domain/entities/dining_table.dart';
import 'package:payneat_pos/features/table/domain/repositories/table_repository.dart';
import 'package:payneat_pos/features/table/domain/usecases/table_usecases.dart';
import 'package:payneat_pos/features/table/presentation/controllers/table_controller.dart';

class _FakeTableRepository implements TableRepository {
  Result<List<DiningTable>> nextGetTablesResult = const Result.success([]);

  @override
  Future<Result<List<DiningTable>>> getTables({
    String? zone,
    String? status,
  }) async => nextGetTablesResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DiningTable _table(
  int id, {
  String zone = 'โซนในร้าน',
  String status = TableStatus.available,
}) => DiningTable(id: id, name: 'A$id', zone: zone, seats: 4, status: status);

void main() {
  late _FakeTableRepository repository;
  late TableController controller;

  setUp(() {
    repository = _FakeTableRepository();
    final session = SessionService(
      storage: StorageService.memory(),
      socket: SocketClient(),
    );
    controller = TableController(
      getTables: GetTablesUseCase(repository),
      setTableStatus: SetTableStatusUseCase(repository),
      session: session,
    );
  });

  tearDown(() => controller.onClose());

  group('TableController', () {
    test('loadTables สำเร็จ → เติมรายการโต๊ะและปิด loading', () async {
      repository.nextGetTablesResult = Result.success([_table(1), _table(2)]);

      await controller.loadTables();

      expect(controller.tables.length, 2);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isNull);
    });

    test(
      'loadTables ล้มเหลว → ตั้ง errorMessage และไม่แตะรายการเดิม',
      () async {
        repository.nextGetTablesResult = Result.success([_table(1)]);
        await controller.loadTables();

        repository.nextGetTablesResult = const Result.failure(
          NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
        );
        await controller.loadTables();

        expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
        expect(controller.tables.length, 1);
      },
    );

    test('zones คืนรายชื่อโซนแบบไม่ซ้ำและเรียงตามตัวอักษร', () async {
      repository.nextGetTablesResult = Result.success([
        _table(1, zone: 'โซนสวน'),
        _table(2, zone: 'โซนในร้าน'),
        _table(3, zone: 'โซนสวน'),
      ]);
      await controller.loadTables();

      // เรียงด้วย String.compareTo ปกติ (เทียบทีละโค้ดยูนิต) ไม่ใช่ Thai locale collation
      expect(controller.zones, ['โซนสวน', 'โซนในร้าน']);
    });

    test('filteredTables กรองได้ทั้งโซนและสถานะพร้อมกัน', () async {
      repository.nextGetTablesResult = Result.success([
        _table(1, zone: 'A', status: TableStatus.available),
        _table(2, zone: 'A', status: TableStatus.occupied),
        _table(3, zone: 'B', status: TableStatus.available),
      ]);
      await controller.loadTables();

      controller.filterByZone('A');
      expect(controller.filteredTables.map((t) => t.id), [1, 2]);

      controller.filterByStatus(TableStatus.available);
      expect(controller.filteredTables.map((t) => t.id), [1]);

      controller.filterByZone(null);
      expect(controller.filteredTables.map((t) => t.id), [1, 3]);
    });

    test('availableCount / occupiedCount นับจากสถานะจริงของโต๊ะ', () async {
      repository.nextGetTablesResult = Result.success([
        _table(1, status: TableStatus.available),
        _table(2, status: TableStatus.available),
        _table(3, status: TableStatus.occupied),
        _table(4, status: TableStatus.billing),
      ]);
      await controller.loadTables();

      expect(controller.availableCount, 2);
      expect(controller.occupiedCount, 1);
    });

    test('onInit แล้ว onClose ต้องไม่โยน exception (unsubscribe ครบ)', () {
      // openTable/changeStatus แตะ Get.toNamed และ AppDialogs (Get.snackbar) จึงต้องมี
      // GetMaterialApp ที่ pump จริง ไม่ครอบคลุมในเทสต์ระดับ unit นี้ (ดู docs/CODING_STANDARDS.md)
      expect(() => controller.onInit(), returnsNormally);
      expect(() => controller.onClose(), returnsNormally);
    });
  });
}
