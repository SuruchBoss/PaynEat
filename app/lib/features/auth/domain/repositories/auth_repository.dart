import '../../../../core/usecases/result.dart';
import '../entities/user.dart';

/// สัญญาของชั้น data ที่ domain ต้องการ
/// (dependency inversion — domain ไม่รู้ว่าเบื้องหลังเป็น REST, GraphQL หรือ mock)
abstract class AuthRepository {
  Future<Result<({String token, User user})>> login({
    required String username,
    required String password,
  });

  Future<Result<User>> getProfile();

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();

  /// อ่านเซสชันที่เก็บไว้ในเครื่อง (ใช้ตอนเปิดแอป)
  ({String token, User user})? cachedSession();
}
