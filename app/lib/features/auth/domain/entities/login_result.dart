// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'branch.dart';
import 'user.dart';

/// ผลลัพธ์การ login — สำเร็จได้ token ใช้งานได้ทันที หรือต้องเลือกสาขาก่อน (ดู
/// docs/tickets/11-multi-branch.md) เมื่อ user มีสิทธิ์เข้ามากกว่า 1 สาขา
sealed class LoginResult {
  const LoginResult();
}

class LoginSuccess extends LoginResult {
  const LoginSuccess({required this.token, required this.user});

  final String token;
  final User user;
}

class LoginNeedsBranchSelection extends LoginResult {
  const LoginNeedsBranchSelection({
    required this.pendingToken,
    required this.branches,
  });

  /// token ชั่วคราวอายุสั้น ใช้เรียกได้แค่ POST /auth/select-branch เท่านั้น
  final String pendingToken;
  final List<Branch> branches;
}
