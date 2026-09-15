import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/network/socket_client.dart';
import 'package:payneat_pos/core/services/session_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/auth/domain/entities/user.dart';
import 'package:payneat_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:payneat_pos/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:payneat_pos/features/auth/domain/usecases/login_usecase.dart';
import 'package:payneat_pos/features/auth/domain/usecases/logout_usecase.dart';
import 'package:payneat_pos/features/auth/presentation/controllers/auth_controller.dart';

/// repository ปลอมที่นับจำนวนครั้งที่แต่ละเมธอดถูกเรียก
/// ใช้ยืนยันว่า controller "ไม่เรียก" use case เมื่อควรจะหยุดตั้งแต่ต้น (เช่น ฟอร์มไม่ผ่าน)
class _FakeAuthRepository implements AuthRepository {
  int loginCallCount = 0;

  @override
  Future<Result<({String token, User user})>> login({
    required String username,
    required String password,
  }) async {
    loginCallCount++;
    return Result.failure(UnexpectedFailure('ไม่ได้ใช้งานในเทสต์นี้'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// เมธอดของ AuthController ที่เรียก Get.offAllNamed / Get.dialog (submitLogin ตอนสำเร็จ,
/// bootstrap, signOut, handleSessionExpired ตอนกำลัง login อยู่) ต้องมี GetMaterialApp
/// ที่ pump ไว้จริงถึงจะเทสต์ต่อได้ — โปรเจกต์นี้เลือกไม่ทำ widget harness ระดับนั้นสำหรับ
/// unit test (ดู docs/CODING_STANDARDS.md) จึงเทสต์เฉพาะส่วนตรรกะที่ไม่แตะการนำทาง
void main() {
  // controller.formKey.currentState เข้าถึง WidgetsBinding แม้ไม่ได้ pump widget ใด ๆ
  // เลย ต้อง ensureInitialized ไว้ก่อน ไม่งั้น GlobalKey จะโยน error ว่า binding ไม่พร้อม
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = _FakeAuthRepository();
    final session = SessionService(
      storage: StorageService.memory(),
      socket: SocketClient(),
    );
    controller = AuthController(
      loginUseCase: LoginUseCase(repository),
      getProfileUseCase: GetProfileUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      repository: repository,
      session: session,
    );
  });

  tearDown(() => controller.onClose());

  group('AuthController', () {
    test('เริ่มต้นซ่อนรหัสผ่านไว้ก่อน', () {
      expect(controller.obscurePassword.value, isTrue);
    });

    test('toggleObscure สลับการซ่อน/แสดงรหัสผ่าน', () {
      controller.toggleObscure();
      expect(controller.obscurePassword.value, isFalse);

      controller.toggleObscure();
      expect(controller.obscurePassword.value, isTrue);
    });

    test(
      'fillDemoAccount เติมชื่อผู้ใช้/รหัสผ่าน และล้าง errorMessage เดิม',
      () {
        controller.errorMessage.value = 'ผิดพลาดจากรอบก่อน';

        controller.fillDemoAccount('waiter1', 'waiter123');

        expect(controller.usernameController.text, 'waiter1');
        expect(controller.passwordController.text, 'waiter123');
        expect(controller.errorMessage.value, isNull);
      },
    );

    test('validateUsername ปฏิเสธค่าว่างหรือเว้นวรรคล้วน', () {
      expect(controller.validateUsername(null), isNotNull);
      expect(controller.validateUsername(''), isNotNull);
      expect(controller.validateUsername('   '), isNotNull);
      expect(controller.validateUsername('admin'), isNull);
    });

    test('validatePassword ปฏิเสธค่าว่างเท่านั้น (ไม่จำกัดความยาว)', () {
      expect(controller.validatePassword(null), isNotNull);
      expect(controller.validatePassword(''), isNotNull);
      expect(controller.validatePassword('1'), isNull);
    });

    test(
      'submitLogin ไม่เรียก use case เมื่อฟอร์มยังไม่ถูก validate '
      '(formKey ไม่ได้ผูกกับ Form widget ใน unit test ทำให้ currentState เป็น null เหมือนฟอร์มไม่ผ่าน)',
      () async {
        controller.usernameController.text = 'admin';
        controller.passwordController.text = 'admin123';

        await controller.submitLogin();

        expect(repository.loginCallCount, 0);
        expect(controller.isLoading.value, isFalse);
      },
    );

    test(
      'handleSessionExpired ไม่ทำอะไรเลยถ้ายังไม่ได้ล็อกอินอยู่ก่อน',
      () async {
        // SessionService ที่สร้างใหม่ยังไม่มี token จึง isLoggedIn เป็น false
        // เมธอดนี้ควร return ทันทีโดยไม่แตะ Get.offAllNamed (ซึ่งจะพังถ้าไม่มี GetMaterialApp)
        await controller.handleSessionExpired();
        // ไม่ throw ก็ถือว่าผ่าน — คือหลักฐานว่า guard clause ทำงานถูกจุด
      },
    );
  });
}
