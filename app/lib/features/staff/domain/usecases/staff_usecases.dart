import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/staff_repository.dart';

class GetStaffUseCase implements UseCase<List<User>, String?> {
  const GetStaffUseCase(this._repository);

  final StaffRepository _repository;

  @override
  Future<Result<List<User>>> call(String? params) =>
      _repository.getStaff(role: params);
}

class CreateStaffParams {
  const CreateStaffParams({
    required this.name,
    required this.username,
    required this.password,
    required this.role,
  });

  final String name;
  final String username;
  final String password;
  final String role;
}

class CreateStaffUseCase implements UseCase<User, CreateStaffParams> {
  const CreateStaffUseCase(this._repository);

  final StaffRepository _repository;

  @override
  Future<Result<User>> call(CreateStaffParams params) => _repository.create(
    name: params.name,
    username: params.username,
    password: params.password,
    role: params.role,
  );
}

class UpdateStaffParams {
  const UpdateStaffParams({
    required this.id,
    this.name,
    this.role,
    this.isActive,
  });

  final int id;
  final String? name;
  final String? role;
  final bool? isActive;
}

class UpdateStaffUseCase implements UseCase<User, UpdateStaffParams> {
  const UpdateStaffUseCase(this._repository);

  final StaffRepository _repository;

  @override
  Future<Result<User>> call(UpdateStaffParams params) => _repository.update(
    params.id,
    name: params.name,
    role: params.role,
    isActive: params.isActive,
  );
}

class DeleteStaffUseCase implements UseCase<void, int> {
  const DeleteStaffUseCase(this._repository);

  final StaffRepository _repository;

  @override
  Future<Result<void>> call(int params) => _repository.delete(params);
}
