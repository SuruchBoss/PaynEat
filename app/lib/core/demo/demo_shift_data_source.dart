part of 'demo_data_sources.dart';

class DemoShiftDataSource implements ShiftRemoteDataSource {
  const DemoShiftDataSource(this._store, this._auth);

  final DemoStore _store;
  final DemoAuthDataSource _auth;

  @override
  Future<ShiftModel?> getCurrent() => _delayed(() {
    final data = _store.currentShift();
    return data == null ? null : ShiftModel.fromJson(data);
  });

  @override
  Future<ShiftModel> open(double openingCash) => _delayed(
    () => ShiftModel.fromJson(
      _store.openShift(
        openingCash: openingCash,
        openedById: _auth.currentUserId ?? 0,
      ),
    ),
  );

  @override
  Future<ShiftModel> close(
    int id, {
    required double countedCash,
    String? note,
  }) => _delayed(
    () => ShiftModel.fromJson(
      _store.closeShift(
        id,
        countedCash: countedCash,
        note: note,
        closedById: _auth.currentUserId ?? 0,
      ),
    ),
  );

  @override
  Future<List<ShiftModel>> getHistory() =>
      _delayed(() => _store.shiftHistory().map(ShiftModel.fromJson).toList());
}
