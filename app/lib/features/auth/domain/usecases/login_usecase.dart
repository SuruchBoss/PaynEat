import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  const LoginParams({required this.username, required this.password});

  final String username;
  final String password;
}

/// เข้าสู่ระบบด้วย username/password
class LoginUseCase implements UseCase<({String token, User user}), LoginParams> {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<({String token, User user})>> call(LoginParams params) {
    return _repository.login(
      username: params.username.trim(),
      password: params.password,
    );
  }
}
