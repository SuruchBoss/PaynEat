import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/usecases/staff_usecases.dart';

/// จัดการบัญชีพนักงาน (admin/manager เท่านั้น)
class StaffController extends GetxController {
  StaffController({
    required GetStaffUseCase getStaff,
    required CreateStaffUseCase createStaff,
    required UpdateStaffUseCase updateStaff,
    required DeleteStaffUseCase deleteStaff,
    required SessionService session,
  })  : _getStaff = getStaff,
        _createStaff = createStaff,
        _updateStaff = updateStaff,
        _deleteStaff = deleteStaff,
        _session = session;

  final GetStaffUseCase _getStaff;
  final CreateStaffUseCase _createStaff;
  final UpdateStaffUseCase _updateStaff;
  final DeleteStaffUseCase _deleteStaff;
  final SessionService _session;

  final RxList<User> staff = <User>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString roleFilter = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  int? get currentUserId => _session.currentUser?.id;

  List<User> get filteredStaff => roleFilter.value == null
      ? staff
      : staff.where((user) => user.role == roleFilter.value).toList(growable: false);

  Map<String, int> get countByRole {
    final counts = <String, int>{};
    for (final user in staff) {
      counts[user.role] = (counts[user.role] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _getStaff(null);

    isLoading.value = false;
    result.fold(
      onSuccess: staff.assignAll,
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  void filterByRole(String? role) => roleFilter.value = role;

  Future<bool> create({
    required String name,
    required String username,
    required String password,
    required String role,
  }) async {
    isSaving.value = true;
    final result = await _createStaff(
      CreateStaffParams(name: name, username: username, password: password, role: role),
    );
    isSaving.value = false;

    return result.fold(
      onSuccess: (_) {
        AppDialogs.success('เพิ่มพนักงานแล้ว');
        load();
        return true;
      },
      onFailure: (failure) {
        AppDialogs.error(failure.message);
        return false;
      },
    );
  }

  Future<void> updateRole(User user, String role) async {
    final result = await _updateStaff(UpdateStaffParams(id: user.id, role: role));
    result.fold(
      onSuccess: (_) {
        AppDialogs.success('เปลี่ยนบทบาทของ ${user.name} แล้ว');
        load();
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  Future<void> toggleActive(User user) async {
    final result = await _updateStaff(
      UpdateStaffParams(id: user.id, isActive: !user.isActive),
    );
    result.fold(
      onSuccess: (_) {
        AppDialogs.success(
          user.isActive ? 'ปิดการใช้งานบัญชีแล้ว' : 'เปิดการใช้งานบัญชีแล้ว',
        );
        load();
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  Future<void> delete(User user) async {
    if (user.id == currentUserId) {
      AppDialogs.error('ลบบัญชีของตัวเองไม่ได้');
      return;
    }

    final confirmed = await AppDialogs.confirm(
      title: 'ลบพนักงาน',
      message: 'ต้องการลบบัญชีของ ${user.name} ใช่หรือไม่?',
      confirmLabel: 'ลบบัญชี',
      destructive: true,
    );
    if (!confirmed) return;

    final result = await _deleteStaff(user.id);
    result.fold(
      onSuccess: (_) {
        AppDialogs.success('ลบบัญชีแล้ว');
        load();
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  String roleLabel(String role) => UserRole.label(role);
}
