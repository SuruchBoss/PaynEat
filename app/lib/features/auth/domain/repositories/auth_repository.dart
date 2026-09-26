// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/usecases/result.dart';
import '../entities/branch.dart';
import '../entities/login_result.dart';
import '../entities/user.dart';

/// สัญญาของชั้น data ที่ domain ต้องการ
/// (dependency inversion — domain ไม่รู้ว่าเบื้องหลังเป็น REST, GraphQL หรือ mock)
abstract class AuthRepository {
  Future<Result<LoginResult>> login({
    required String username,
    required String password,
  });

  /// เลือก/ยืนยันสาขา (ดู docs/tickets/11-multi-branch.md) — ใช้ทั้งแลก pendingToken จาก
  /// [LoginNeedsBranchSelection] ให้เป็น session ใช้งานได้จริงครั้งแรก และสลับสาขาภายหลังตอน
  /// login แล้ว (ส่ง token ของ session ปัจจุบันเข้ามาแทน) — branchId เป็น null ได้เฉพาะ admin
  /// (โหมด "ทุกสาขา")
  Future<Result<({String token, User user})>> selectBranch({
    required String token,
    required int? branchId,
  });

  /// สาขาที่ user ปัจจุบันมีสิทธิ์เข้าถึง — ใช้แสดงตัวเลือกตอนสลับสาขา
  Future<Result<List<Branch>>> listMyBranches();

  Future<Result<User>> getProfile();

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();

  /// อ่านเซสชันที่เก็บไว้ในเครื่อง (ใช้ตอนเปิดแอป)
  ({String token, User user})? cachedSession();
}
