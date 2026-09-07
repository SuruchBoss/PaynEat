import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/settings/domain/entities/store_settings.dart';
import 'package:payneat_pos/features/settings/domain/repositories/settings_repository.dart';
import 'package:payneat_pos/features/settings/domain/usecases/settings_usecases.dart';
import 'package:payneat_pos/features/settings/presentation/controllers/settings_controller.dart';

class _FakeSettingsRepository implements SettingsRepository {
  Result<StoreSettings> nextGetResult = Result.success(StoreSettings.fallback);

  @override
  Future<Result<StoreSettings>> get() async => nextGetResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeSettingsRepository repository;
  late SettingsController controller;

  setUp(() {
    repository = _FakeSettingsRepository();
    controller = SettingsController(
      getSettings: GetSettingsUseCase(repository),
      updateSettings: UpdateSettingsUseCase(repository),
    );
  });

  tearDown(() => controller.onClose());

  group('SettingsController', () {
    // save() ทุกเส้นทาง (validation guard, สำเร็จ, ล้มเหลว) เรียก AppDialogs.error/success
    // โดยตรงทุกครั้ง จึงไม่มี path ใดของ save() ที่ทดสอบได้เลยโดยไม่มี GetMaterialApp
    // ที่ pump จริง (ดู docs/CODING_STANDARDS.md) — ทดสอบเฉพาะ load()

    test('load สำเร็จ → เติมค่าตั้งค่าและข้อความในช่องกรอกให้ตรงกัน', () async {
      repository.nextGetResult = const Result.success(
        StoreSettings(
          storeName: 'ร้านทดสอบ',
          currency: 'THB',
          vatRate: 0.08,
          serviceChargeRate: 0.05,
          vatIncluded: true,
        ),
      );

      await controller.load();

      expect(controller.settings.value.storeName, 'ร้านทดสอบ');
      expect(controller.storeNameController.text, 'ร้านทดสอบ');
      expect(controller.vatController.text, '8');
      expect(controller.serviceChargeController.text, '5');
      expect(controller.vatIncluded.value, isTrue);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isNull);
    });

    test('load ล้มเหลว → ตั้ง errorMessage และไม่แตะช่องกรอก', () async {
      repository.nextGetResult = const Result.failure(
        NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
      );

      await controller.load();

      expect(controller.errorMessage.value, 'ต่อเซิร์ฟเวอร์ไม่ได้');
      expect(controller.storeNameController.text, isEmpty);
    });

    test('onInit เรียก load ให้อัตโนมัติโดยไม่โยน exception', () {
      expect(() => controller.onInit(), returnsNormally);
    });
  });
}
