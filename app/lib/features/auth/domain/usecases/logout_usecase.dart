import '../repositories/auth_repository.dart';

/// ออกจากระบบ — ล้าง token ที่เก็บไว้ในเครื่อง
class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
