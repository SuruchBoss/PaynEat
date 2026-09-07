import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required StorageService storage,
  }) : _remote = remote,
       _storage = storage;

  final AuthRemoteDataSource _remote;
  final StorageService _storage;

  @override
  Future<Result<({String token, User user})>> login({
    required String username,
    required String password,
  }) => guard(() async {
    final result = await _remote.login(username, password);
    await _storage.saveSession(token: result.token, user: result.user.toJson());
    return (token: result.token, user: result.user as User);
  });

  @override
  Future<Result<User>> getProfile() => guard(() async {
    final user = await _remote.getProfile();
    final token = _storage.token;
    if (token != null) {
      await _storage.saveSession(token: token, user: user.toJson());
    }
    return user as User;
  });

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => guard(() => _remote.changePassword(currentPassword, newPassword));

  @override
  Future<void> logout() => _storage.clear();

  @override
  ({String token, User user})? cachedSession() {
    final token = _storage.token;
    final user = _storage.user;
    if (token == null || user == null) return null;
    try {
      return (token: token, user: UserModel.fromJson(user) as User);
    } catch (_) {
      return null;
    }
  }
}
