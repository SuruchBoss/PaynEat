// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/login_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_my_branches_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/select_branch_usecase.dart';

/// ควบคุมการเข้าสู่ระบบและอายุของเซสชัน
///
/// เป็น controller ตัวเดียวที่ตั้งเป็น permanent เพราะทุกหน้าจอต้องรู้ว่าใครล็อกอินอยู่
class AuthController extends GetxController {
  AuthController({
    required LoginUseCase loginUseCase,
    required SelectBranchUseCase selectBranchUseCase,
    required GetMyBranchesUseCase getMyBranchesUseCase,
    required GetProfileUseCase getProfileUseCase,
    required LogoutUseCase logoutUseCase,
    required AuthRepository repository,
    required SessionService session,
  }) : _login = loginUseCase,
       _selectBranch = selectBranchUseCase,
       _getMyBranches = getMyBranchesUseCase,
       _getProfile = getProfileUseCase,
       _logout = logoutUseCase,
       _repository = repository,
       _session = session;

  final LoginUseCase _login;
  final SelectBranchUseCase _selectBranch;
  final GetMyBranchesUseCase _getMyBranches;
  final GetProfileUseCase _getProfile;
  final LogoutUseCase _logout;
  final AuthRepository _repository;
  final SessionService _session;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxnString errorMessage = RxnString();

  // เลือกสาขาตอน login ครั้งแรก (ดู docs/tickets/11-multi-branch.md) — pendingToken ไม่เก็บลง
  // storage เลย อยู่แค่ในหน่วยความจำระหว่างขั้นตอนนี้เท่านั้น
  final RxList<Branch> pendingBranches = <Branch>[].obs;
  final RxBool isSelectingBranch = false.obs;
  String? _pendingToken;

  // สลับสาขาภายหลังตอน login แล้ว (เช่นจากหน้าบัญชี)
  final RxList<Branch> myBranches = <Branch>[].obs;
  final RxBool isLoadingMyBranches = false.obs;
  final RxBool isSwitchingBranch = false.obs;

  User? get currentUser => _session.currentUser;

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void toggleObscure() => obscurePassword.toggle();

  /// เติมบัญชีเดโมให้กรอกเร็ว ๆ ตอนนำเสนอผลงาน
  void fillDemoAccount(String username, String password) {
    usernameController.text = username;
    passwordController.text = password;
    errorMessage.value = null;
  }

  /// ตรวจเซสชันเดิมตอนเปิดแอป แล้วพาไปหน้าที่เหมาะกับบทบาท
  Future<void> bootstrap() async {
    final cached = _repository.cachedSession();
    if (cached == null) {
      await Get.offAllNamed<void>(AppRoutes.login);
      return;
    }

    _session.start(user: cached.user, token: cached.token);

    // ยืนยันกับเซิร์ฟเวอร์ว่า token ยังไม่หมดอายุ
    final result = await _getProfile();
    result.fold(
      onSuccess: (user) {
        _session.updateUser(user);
        Get.offAllNamed<void>(AppRoutes.home);
      },
      onFailure: (failure) async {
        if (failure is NetworkFailure) {
          // ออฟไลน์ชั่วคราว — ให้ใช้เซสชันที่เก็บไว้ไปก่อน
          Get.offAllNamed<void>(AppRoutes.home);
          return;
        }
        await _session.end();
        Get.offAllNamed<void>(AppRoutes.login);
      },
    );
  }

  Future<void> submitLogin() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    errorMessage.value = null;

    final result = await _login(
      LoginParams(
        username: usernameController.text,
        password: passwordController.text,
      ),
    );

    isLoading.value = false;

    result.fold(
      onSuccess: (loginResult) {
        switch (loginResult) {
          case LoginSuccess(:final token, :final user):
            passwordController.clear();
            _session.start(user: user, token: token);
            Get.offAllNamed<void>(AppRoutes.home);
          case LoginNeedsBranchSelection(:final pendingToken, :final branches):
            _pendingToken = pendingToken;
            pendingBranches.assignAll(branches);
            Get.toNamed<void>(AppRoutes.branchSelection);
        }
      },
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  /// ยืนยันสาขาที่เลือกตอน login ครั้งแรก (หน้า [AppRoutes.branchSelection])
  Future<void> submitBranchSelection(int branchId) async {
    final token = _pendingToken;
    if (token == null) return;

    isSelectingBranch.value = true;
    final result = await _selectBranch(
      SelectBranchParams(token: token, branchId: branchId),
    );
    isSelectingBranch.value = false;

    result.fold(
      onSuccess: (data) {
        _pendingToken = null;
        pendingBranches.clear();
        passwordController.clear();
        _session.start(user: data.user, token: data.token);
        Get.offAllNamed<void>(AppRoutes.home);
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  /// โหลดสาขาที่สลับได้ (หน้าบัญชี) — เรียกใหม่ทุกครั้งที่เปิด picker เพราะสิทธิ์อาจเปลี่ยนได้
  Future<void> loadMyBranches() async {
    isLoadingMyBranches.value = true;
    final result = await _getMyBranches();
    isLoadingMyBranches.value = false;

    result.fold(
      onSuccess: myBranches.assignAll,
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  /// สลับสาขาตอน login อยู่แล้ว (ต่างจาก [submitBranchSelection] ตรงใช้ token ของ session
  /// ปัจจุบัน ไม่ใช่ pendingToken) — branchId เป็น null ได้เฉพาะ admin (โหมด "ทุกสาขา")
  Future<void> switchBranch(int? branchId) async {
    final token = _session.token;
    if (token == null) return;

    isSwitchingBranch.value = true;
    final result = await _selectBranch(
      SelectBranchParams(token: token, branchId: branchId),
    );
    isSwitchingBranch.value = false;

    result.fold(
      onSuccess: (data) {
        _session.start(user: data.user, token: data.token);
        AppDialogs.success(
          'branch_switch_success'.trParams({
            'branch': data.user.branchName ?? 'branch_all_branches'.tr,
          }),
        );
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  Future<void> signOut() async {
    final confirmed = await AppDialogs.confirm(
      title: 'auth_logout'.tr,
      message: 'auth_logout_confirm_message'.tr,
      confirmLabel: 'auth_logout'.tr,
      destructive: true,
    );
    if (!confirmed) return;

    await _logout();
    await _session.end();
    Get.offAllNamed<void>(AppRoutes.login);
  }

  /// ถูกเรียกจาก ApiClient เมื่อ token หมดอายุกลางคัน
  Future<void> handleSessionExpired() async {
    if (!_session.isLoggedIn) return;
    await _session.end();
    AppDialogs.error('auth_session_expired_message'.tr);
    Get.offAllNamed<void>(AppRoutes.login);
  }

  String? validateUsername(String? value) =>
      (value == null || value.trim().isEmpty)
      ? 'auth_username_required'.tr
      : null;

  String? validatePassword(String? value) =>
      (value == null || value.isEmpty) ? 'auth_password_required'.tr : null;
}
