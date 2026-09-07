import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/dining_table_model.dart';

abstract class TableRemoteDataSource {
  Future<List<DiningTableModel>> getTables({String? zone, String? status});
  Future<List<String>> getZones();
  Future<DiningTableModel> setStatus(int id, String status);
  Future<DiningTableModel> create(Map<String, dynamic> body);
  Future<DiningTableModel> update(int id, Map<String, dynamic> body);
  Future<void> delete(int id);
}

class TableRemoteDataSourceImpl implements TableRemoteDataSource {
  const TableRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<DiningTableModel>> getTables({String? zone, String? status}) async {
    final result = await _client.get(
      ApiEndpoints.tables,
      query: {'zone': zone, 'status': status},
    );
    return result.asList.map(DiningTableModel.fromJson).toList(growable: false);
  }

  @override
  Future<List<String>> getZones() async {
    final result = await _client.get(ApiEndpoints.tableZones);
    return (result.data as List? ?? const []).map((zone) => zone.toString()).toList(growable: false);
  }

  @override
  Future<DiningTableModel> setStatus(int id, String status) async {
    final result = await _client.patch(ApiEndpoints.tableStatus(id), body: {'status': status});
    return DiningTableModel.fromJson(result.asMap);
  }

  @override
  Future<DiningTableModel> create(Map<String, dynamic> body) async {
    final result = await _client.post(ApiEndpoints.tables, body: body);
    return DiningTableModel.fromJson(result.asMap);
  }

  @override
  Future<DiningTableModel> update(int id, Map<String, dynamic> body) async {
    final result = await _client.patch(ApiEndpoints.table(id), body: body);
    return DiningTableModel.fromJson(result.asMap);
  }

  @override
  Future<void> delete(int id) => _client.delete(ApiEndpoints.table(id));
}
