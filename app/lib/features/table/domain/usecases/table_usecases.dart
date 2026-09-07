import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dining_table.dart';
import '../repositories/table_repository.dart';

class TableFilter {
  const TableFilter({this.zone, this.status});

  final String? zone;
  final String? status;

  static const TableFilter none = TableFilter();
}

/// ดึงผังโต๊ะพร้อมออเดอร์ที่เปิดอยู่
class GetTablesUseCase implements UseCase<List<DiningTable>, TableFilter> {
  const GetTablesUseCase(this._repository);

  final TableRepository _repository;

  @override
  Future<Result<List<DiningTable>>> call(TableFilter params) =>
      _repository.getTables(zone: params.zone, status: params.status);
}

class SetTableStatusParams {
  const SetTableStatusParams({required this.id, required this.status});

  final int id;
  final String status;
}

/// เปลี่ยนสถานะโต๊ะ (จอง / ว่าง / เรียกเก็บเงิน)
class SetTableStatusUseCase implements UseCase<DiningTable, SetTableStatusParams> {
  const SetTableStatusUseCase(this._repository);

  final TableRepository _repository;

  @override
  Future<Result<DiningTable>> call(SetTableStatusParams params) =>
      _repository.setStatus(params.id, params.status);
}

class SaveTableParams {
  const SaveTableParams({this.id, required this.name, this.zone, this.seats});

  final int? id;
  final String name;
  final String? zone;
  final int? seats;
}

class SaveTableUseCase implements UseCase<DiningTable, SaveTableParams> {
  const SaveTableUseCase(this._repository);

  final TableRepository _repository;

  @override
  Future<Result<DiningTable>> call(SaveTableParams params) => _repository.save(
        id: params.id,
        name: params.name,
        zone: params.zone,
        seats: params.seats,
      );
}

class DeleteTableUseCase implements UseCase<void, int> {
  const DeleteTableUseCase(this._repository);

  final TableRepository _repository;

  @override
  Future<Result<void>> call(int params) => _repository.delete(params);
}

class GetZonesUseCase implements NoParamsUseCase<List<String>> {
  const GetZonesUseCase(this._repository);

  final TableRepository _repository;

  @override
  Future<Result<List<String>>> call() => _repository.getZones();
}
