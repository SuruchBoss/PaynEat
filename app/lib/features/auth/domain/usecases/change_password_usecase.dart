import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ChangePasswordParams {
  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

class ChangePasswordUseCase implements UseCase<void, ChangePasswordParams> {
  const ChangePasswordUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(ChangePasswordParams params) => _repository.changePassword(
        currentPassword: params.currentPassword,
        newPassword: params.newPassword,
      );
}
