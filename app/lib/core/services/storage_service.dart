import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../constants/app_constants.dart';

/// เก็บข้อมูลถาวรในเครื่อง (token / โปรไฟล์ผู้ใช้)
class StorageService {
  StorageService(this._box);

  final GetStorage _box;

  static Future<StorageService> init() async {
    await GetStorage.init();
    return StorageService(GetStorage());
  }

  String? get token => _box.read<String>(StorageKeys.token);

  Map<String, dynamic>? get user {
    final raw = _box.read<String>(StorageKeys.user);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    await _box.write(StorageKeys.token, token);
    await _box.write(StorageKeys.user, jsonEncode(user));
  }

  Future<void> clear() async {
    await _box.remove(StorageKeys.token);
    await _box.remove(StorageKeys.user);
  }
}
