part of 'demo_data_sources.dart';

class DemoAuthDataSource implements AuthRemoteDataSource {
  DemoAuthDataSource(this._store);

  final DemoStore _store;
  String? _token;

  @override
  Future<({String token, UserModel user})> login(
    String username,
    String password,
  ) => _delayed(() {
    final result = _store.login(username, password);
    _token = result['token'] as String;
    return (
      token: _token!,
      user: UserModel.fromJson(result['user'] as Map<String, dynamic>),
    );
  });

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
