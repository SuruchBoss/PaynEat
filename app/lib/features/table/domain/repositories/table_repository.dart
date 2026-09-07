import '../../../../core/usecases/result.dart';
import '../entities/dining_table.dart';

abstract class TableRepository {
  Future<Result<List<DiningTable>>> getTables({String? zone, String? status});
  Future<Result<List<String>>> getZones();
  Future<Result<DiningTable>> setStatus(int id, String status);
  Future<Result<DiningTable>> save({int? id, required String name, String? zone, int? seats});
  Future<Result<void>> delete(int id);
}
