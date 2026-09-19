part of 'demo_data_sources.dart';

class DemoTableDataSource implements TableRemoteDataSource {
  const DemoTableDataSource(this._store);

  final DemoStore _store;

  @override
  Future<List<DiningTableModel>> getTables({String? zone, String? status}) =>
      _delayed(
        () => _store
            .tableList(zone: zone, status: status)
            .map(DiningTableModel.fromJson)
            .toList(growable: false),
      );

  @override
  Future<List<String>> getZones() => _delayed(() => _store.zones());

  @override
  Future<DiningTableModel> setStatus(int id, String status) => _delayed(
    () => DiningTableModel.fromJson(_store.setTableStatus(id, status)),
  );

  @override
  Future<DiningTableModel> create(Map<String, dynamic> body) =>
      _delayed(() => DiningTableModel.fromJson(_store.saveTable(body)));

  @override
  Future<DiningTableModel> update(int id, Map<String, dynamic> body) =>
      _delayed(() => DiningTableModel.fromJson(_store.saveTable(body, id: id)));

  @override
  Future<void> delete(int id) => _delayed(() => _store.deleteTable(id));

  @override
  Future<DiningTableModel> regenerateQrToken(int id) =>
      _delayed(() => DiningTableModel.fromJson(_store.regenerateQrToken(id)));
}
