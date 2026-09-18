part of 'demo_data_sources.dart';

/// ดู docs/DECISIONS.md #36 — โหมดสาธิตมีสาขาเดียว (ไม่มี branch_id ใน demo store เลย) จึงไม่มี
/// user คนไหนต้องเลือกสาขาตอน login เลย `login()` จึงคืน `LoginSuccess` เสมอ และ
/// `listMyBranches()` คืนสาขาสมมติสาขาเดียวไว้ให้ UI ที่ใช้ร่วมกับ backend จริงยังทำงานได้
/// (แต่หน้า "สลับสาขา" จะถูกซ่อนในโหมดสาธิตเพราะมีแค่สาขาเดียวให้เลือก)
class DemoAuthDataSource implements AuthRemoteDataSource {
  DemoAuthDataSource(this._store);

  static const _mainBranch = BranchModel(id: 1, name: 'สาขาหลัก (สาธิต)');

  final DemoStore _store;
  String? _token;

  @override
  Future<LoginResult> login(String username, String password) => _delayed(() {
    final result = _store.login(username, password);
    _token = result['token'] as String;
    return LoginSuccess(
      token: _token!,
      user: UserModel.fromJson(result['user'] as Map<String, dynamic>),
    );
  });

  @override
  Future<({String token, UserModel user})> selectBranch({
    required String token,
    required int? branchId,
  }) => _delayed(() {
    _token = token;
    return (token: token, user: UserModel.fromJson(_store.profile(token)));
  });

  @override
  Future<List<BranchModel>> listMyBranches() =>
      _delayed(() => const [_mainBranch]);

  @override
  Future<UserModel> getProfile() =>
      _delayed(() => UserModel.fromJson(_store.profile(_token)));

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {}

  /// ใช้หา id ของผู้ใช้ปัจจุบันตอนสร้างออเดอร์/รับเงิน
  int? get currentUserId => int.tryParse(_token?.split('-').last ?? '');
}
