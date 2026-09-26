// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/login_result.dart';
import '../models/branch_model.dart';
import '../models/user_model.dart';

/// คุยกับ REST API เรื่องการยืนยันตัวตน
abstract class AuthRemoteDataSource {
  Future<LoginResult> login(String username, String password);

  /// ดู docs/tickets/11-multi-branch.md — token คือ pendingToken (login ครั้งแรกที่มีหลายสาขา)
  /// หรือ token ปกติที่ login แล้ว (สลับสาขาภายหลัง)
  Future<({String token, UserModel user})> selectBranch({
    required String token,
    required int? branchId,
  });

  Future<List<BranchModel>> listMyBranches();

  Future<UserModel> getProfile();
  Future<void> changePassword(String currentPassword, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<LoginResult> login(String username, String password) async {
    final result = await _client.post(
      ApiEndpoints.login,
      body: {'username': username, 'password': password},
    );
    final data = result.asMap;
    if (data['needsBranchSelection'] == true) {
      return LoginNeedsBranchSelection(
        pendingToken: data['pendingToken'] as String,
        branches: (data['branches'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BranchModel.fromJson)
            .toList(growable: false),
      );
    }
    return LoginSuccess(
      token: data['token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  @override
  Future<({String token, UserModel user})> selectBranch({
    required String token,
    required int? branchId,
  }) async {
    final result = await _client.post(
      ApiEndpoints.selectBranch,
      body: {'branchId': branchId},
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = result.asMap;
    return (
      token: data['token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  @override
  Future<List<BranchModel>> listMyBranches() async {
    final result = await _client.get(ApiEndpoints.branchesMine);
    return result.asList.map(BranchModel.fromJson).toList(growable: false);
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
