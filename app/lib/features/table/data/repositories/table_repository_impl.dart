import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/dining_table.dart';
import '../../domain/repositories/table_repository.dart';
import '../datasources/table_remote_data_source.dart';

class TableRepositoryImpl implements TableRepository {
  const TableRepositoryImpl(this._remote);

  final TableRemoteDataSource _remote;

  @override
  Future<Result<List<DiningTable>>> getTables({String? zone, String? status}) =>
      guard(() async => await _remote.getTables(zone: zone, status: status));

  @override
  Future<Result<List<String>>> getZones() => guard(() => _remote.getZones());

  @override
  Future<Result<DiningTable>> setStatus(int id, String status) =>
      guard(() async => await _remote.setStatus(id, status));

  @override
  Future<Result<DiningTable>> save({
    int? id,
    required String name,
    String? zone,
    int? seats,
  }) =>
      guard(() async {
        final body = <String, dynamic>{
          'name': name,
          if (zone != null && zone.isNotEmpty) 'zone': zone,
          if (seats != null) 'seats': seats,
        };
        return id == null ? await _remote.create(body) : await _remote.update(id, body);
      });

  @override
  Future<Result<void>> delete(int id) => guard(() => _remote.delete(id));
}
