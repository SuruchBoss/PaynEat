// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SelectBranchParams {
  const SelectBranchParams({required this.token, required this.branchId});

  /// pendingToken (login ครั้งแรกที่มีหลายสาขา) หรือ token ปกติที่ login แล้ว (สลับสาขาภายหลัง)
  final String token;

  /// null ได้เฉพาะ admin (โหมด "ทุกสาขา" ดู docs/tickets/11-multi-branch.md)
  final int? branchId;
}

class SelectBranchUseCase
    implements UseCase<({String token, User user}), SelectBranchParams> {
  const SelectBranchUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<({String token, User user})>> call(SelectBranchParams params) {
    return _repository.selectBranch(
      token: params.token,
      branchId: params.branchId,
    );
  }
}
