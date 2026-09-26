// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/branch.dart';
import '../repositories/auth_repository.dart';

/// สาขาที่ user ปัจจุบันมีสิทธิ์เข้าถึง — ใช้แสดงตัวเลือกตอนสลับสาขาที่หน้าบัญชี
class GetMyBranchesUseCase implements NoParamsUseCase<List<Branch>> {
  const GetMyBranchesUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<List<Branch>>> call() => _repository.listMyBranches();
}
