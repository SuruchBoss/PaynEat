import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/usecases/promotion_usecases.dart';

/// จัดการโปรโมชัน (สำหรับผู้จัดการ/แอดมิน) — เพิ่ม แก้ไข ลบ และเปิด-ปิดใช้งาน
class PromotionsController extends GetxController {
  PromotionsController({
    required GetPromotionsUseCase getPromotions,
    required SavePromotionUseCase savePromotion,
    required SetPromotionActiveUseCase setPromotionActive,
    required DeletePromotionUseCase deletePromotion,
  }) : _getPromotions = getPromotions,
       _savePromotion = savePromotion,
       _setPromotionActive = setPromotionActive,
       _deletePromotion = deletePromotion;

  final GetPromotionsUseCase _getPromotions;
  final SavePromotionUseCase _savePromotion;
  final SetPromotionActiveUseCase _setPromotionActive;
  final DeletePromotionUseCase _deletePromotion;

  final RxList<Promotion> promotions = <Promotion>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _getPromotions(false);
    isLoading.value = false;
    result.fold(
      onSuccess: (data) => promotions.assignAll(data),
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  Future<void> toggleActive(Promotion promotion) async {
    final result = await _setPromotionActive(
      SetPromotionActiveParams(id: promotion.id, isActive: !promotion.isActive),
    );
    result.fold(
      onSuccess: (updated) {
        final index = promotions.indexWhere((row) => row.id == updated.id);
        if (index >= 0) promotions[index] = updated;
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  Future<void> save({int? id, required PromotionFormData data}) async {
    isSaving.value = true;
    final result = await _savePromotion(
      SavePromotionParams(id: id, data: data),
    );
    isSaving.value = false;

    result.fold(
      onSuccess: (_) {
        AppDialogs.success(
          id == null
              ? 'promotion_created_success'.tr
              : 'promotion_updated_success'.tr,
        );
        Get.back<void>();
        load();
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  Future<void> delete(Promotion promotion) async {
    final confirmed = await AppDialogs.confirm(
      title: 'promotion_delete_title'.tr,
      message: 'promotion_delete_confirm'.trParams({'name': promotion.name}),
      confirmLabel: 'common_delete'.tr,
      destructive: true,
    );
    if (!confirmed) return;

    final result = await _deletePromotion(promotion.id);
    result.fold(
      onSuccess: (_) {
        promotions.removeWhere((row) => row.id == promotion.id);
        AppDialogs.success('promotion_deleted_success'.tr);
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  Future<void> openForm({Promotion? promotion}) async {
    await Get.toNamed<void>(
      AppRoutes.promotionForm,
      arguments: {'promotion': promotion},
    );
  }
}
