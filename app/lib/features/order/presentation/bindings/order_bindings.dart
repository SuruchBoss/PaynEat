import 'package:get/get.dart';

import '../../../../core/services/offline_order_queue_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../menu/domain/usecases/menu_usecases.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';
import '../../../settings/domain/usecases/settings_usecases.dart';
import '../../domain/usecases/order_usecases.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_detail_controller.dart';

/// DI ของหน้ารับออเดอร์ (เมนู + ตะกร้า)
class OrderTakingBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      MenuBrowseController(
        getMenuItems: Get.find<GetMenuItemsUseCase>(),
        getCategories: Get.find<GetCategoriesUseCase>(),
      ),
    );
    Get.put(
      CartController(
        createOrder: Get.find<CreateOrderUseCase>(),
        addItems: Get.find<AddOrderItemsUseCase>(),
        sendToKitchen: Get.find<SendToKitchenUseCase>(),
        getSettings: Get.find<GetSettingsUseCase>(),
        offlineQueue: Get.find<OfflineOrderQueueService>(),
      ),
    );
  }
}

/// DI ของหน้ารายละเอียดออเดอร์
class OrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      OrderDetailController(
        getOrder: Get.find<GetOrderUseCase>(),
        sendToKitchen: Get.find<SendToKitchenUseCase>(),
        updateItem: Get.find<UpdateOrderItemUseCase>(),
        removeItem: Get.find<RemoveOrderItemUseCase>(),
        updateItemStatus: Get.find<UpdateOrderItemStatusUseCase>(),
        applyDiscount: Get.find<ApplyDiscountUseCase>(),
        cancelOrder: Get.find<CancelOrderUseCase>(),
        moveOrderTable: Get.find<MoveOrderTableUseCase>(),
        mergeOrders: Get.find<MergeOrdersUseCase>(),
        redeemPromotionCode: Get.find<RedeemPromotionCodeUseCase>(),
        removePromotion: Get.find<RemovePromotionUseCase>(),
        getEligiblePromotions: Get.find<GetEligiblePromotionsUseCase>(),
        session: Get.find<SessionService>(),
      ),
    );
  }
}
