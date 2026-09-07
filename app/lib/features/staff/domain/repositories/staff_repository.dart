import '../../../../core/usecases/result.dart';
import '../../../auth/domain/entities/user.dart';

abstract class StaffRepository {
  Future<Result<List<User>>> getStaff({String? role});
  Future<Result<User>> create({
    required String name,
    required String username,
    required String password,
    required String role,
  });
  Future<Result<User>> update(
    int id, {
    String? name,
    String? role,
    bool? isActive,
  });
  Future<Result<User>> resetPassword(int id, String password);
  Future<Result<void>> delete(int id);
}
