import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// ดึงโปรไฟล์ผู้ใช้ปัจจุบัน — ใช้ตรวจว่า token ที่เก็บไว้ยังใช้ได้อยู่ไหม
class GetProfileUseCase implements NoParamsUseCase<User> {
  const GetProfileUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<User>> call() => _repository.getProfile();
}
