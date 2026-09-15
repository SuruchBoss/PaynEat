part of 'demo_store.dart';

// ---------------------------------------------------------------- auth ---
extension DemoStoreAuth on DemoStore {
  Map<String, dynamic> login(String username, String password) {
    final user = users.firstWhere(
      (row) => row['username'] == username && row['password'] == password,
      orElse: () => throw ApiException(
        message: 'auth_invalid_credentials'.tr,
        statusCode: 401,
      ),
    );
    return {'token': 'demo-token-${user['id']}', 'user': _publicUser(user)};
  }

  Map<String, dynamic> _publicUser(Map<String, dynamic> user) => {
    'id': user['id'],
    'name': user['name'],
    'username': user['username'],
    'role': user['role'],
    'isActive': user['isActive'],
  };

  Map<String, dynamic> profile(String? token) {
    final id = int.tryParse(token?.split('-').last ?? '');
    final user = users.firstWhere(
      (row) => row['id'] == id,
      orElse: () => throw ApiException(
        message: 'auth_demo_session_expired'.tr,
        statusCode: 401,
      ),
    );
    return _publicUser(user);
  }

  List<Map<String, dynamic>> staff() =>
      users.map(_publicUser).toList(growable: false);

  Map<String, dynamic> createStaff({
    required String name,
    required String username,
    required String password,
    required String role,
  }) {
    if (users.any((row) => row['username'] == username)) {
      throw ApiException(message: 'auth_username_taken'.tr, statusCode: 409);
    }
    final user = {
      'id': _nextId(),
      'name': name,
      'username': username,
      'password': password,
      'role': role,
      'isActive': true,
    };
    users.add(user);
    return _publicUser(user);
  }

  Map<String, dynamic> updateStaff(int id, Map<String, dynamic> changes) {
    final user = _findUser(id);
    changes.forEach((key, value) => user[key] = value);
    return _publicUser(user);
  }

  void deleteStaff(int id) => users.removeWhere((row) => row['id'] == id);

  Map<String, dynamic> _findUser(int id) => users.firstWhere(
    (row) => row['id'] == id,
    orElse: () =>
        throw ApiException(message: 'auth_user_not_found'.tr, statusCode: 404),
  );
}
