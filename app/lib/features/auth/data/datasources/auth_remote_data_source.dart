import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

/// คุยกับ REST API เรื่องการยืนยันตัวตน
abstract class AuthRemoteDataSource {
  Future<({String token, UserModel user})> login(
    String username,
    String password,
  );
  Future<UserModel> getProfile();
  Future<void> changePassword(String currentPassword, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<({String token, UserModel user})> login(
    String username,
    String password,
  ) async {
    final result = await _client.post(
      ApiEndpoints.login,
      body: {'username': username, 'password': password},
    );
    final data = result.asMap;
    return (
      token: data['token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  @override
  Future<UserModel> getProfile() async {
    final result = await _client.get(ApiEndpoints.me);
    return UserModel.fromJson(result.asMap);
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _client.post(
      ApiEndpoints.changePassword,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
