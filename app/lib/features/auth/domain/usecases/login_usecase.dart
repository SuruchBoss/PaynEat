// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/login_result.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  const LoginParams({required this.username, required this.password});

  final String username;
  final String password;
}

/// เข้าสู่ระบบด้วย username/password — ดู [LoginResult] สำหรับกรณีที่ต้องเลือกสาขาก่อน
/// (docs/tickets/11-multi-branch.md)
class LoginUseCase implements UseCase<LoginResult, LoginParams> {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<LoginResult>> call(LoginParams params) {
    return _repository.login(
      username: params.username.trim(),
      password: params.password,
    );
  }
}
