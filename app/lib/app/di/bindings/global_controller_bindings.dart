// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:get/get.dart';

import '../../../core/services/session_service.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';
import '../../../features/auth/domain/usecases/get_my_branches_usecase.dart';
import '../../../features/auth/domain/usecases/get_profile_usecase.dart';
import '../../../features/auth/domain/usecases/login_usecase.dart';
import '../../../features/auth/domain/usecases/logout_usecase.dart';
import '../../../features/auth/domain/usecases/select_branch_usecase.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';

/// controller ที่ต้องมีตัวเดียวตลอดอายุแอป (ไม่ผูกกับหน้าจอไหนโดยเฉพาะ) — ตอนนี้มีแค่
/// `AuthController` เพราะทุกหน้าจอต้องเช็คสถานะล็อกอิน/สิทธิ์ผ่านตัวนี้
void bindGlobalControllers() {
  Get.put<AuthController>(
    AuthController(
      loginUseCase: Get.find<LoginUseCase>(),
      selectBranchUseCase: Get.find<SelectBranchUseCase>(),
      getMyBranchesUseCase: Get.find<GetMyBranchesUseCase>(),
      getProfileUseCase: Get.find<GetProfileUseCase>(),
      logoutUseCase: Get.find<LogoutUseCase>(),
      repository: Get.find<AuthRepository>(),
      session: Get.find<SessionService>(),
    ),
    permanent: true,
  );
}
