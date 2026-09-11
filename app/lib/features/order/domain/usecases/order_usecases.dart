import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../promotion/domain/entities/promotion.dart';
import '../entities/order_item_payload.dart';
import '../entities/cart_line.dart';
import '../entities/order.dart';
import '../entities/order_item.dart';
import '../repositories/order_repository.dart';

/// แปลงตะกร้า → payload ที่ API ต้องการ (กฎการแปลงอยู่ในชั้น domain)
List<OrderItemPayload> cartToPayload(List<CartLine> lines) => lines
    .map(
      (line) => OrderItemPayload(
        menuItemId: line.menuItem.id,
        quantity: line.quantity,
        optionIds: line.optionIds,
        note: line.note,
      ),
    )
    .toList(growable: false);

class OrderListFilter {
  const OrderListFilter({
    this.status,
    this.activeOnly,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 30,
  });

  final String? status;
  final bool? activeOnly;
  final String? dateFrom;
  final String? dateTo;
  final int page;
  final int limit;
}

class GetOrdersUseCase
    implements UseCase<({List<Order> orders, int total}), OrderListFilter> {
  const GetOrdersUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<({List<Order> orders, int total})>> call(
    OrderListFilter params,
  ) => _repository.getOrders(
    status: params.status,
    activeOnly: params.activeOnly,
    dateFrom: params.dateFrom,
    dateTo: params.dateTo,
    page: params.page,
    limit: params.limit,
  );
}

class GetOrderUseCase implements UseCase<Order, int> {
  const GetOrderUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(int params) => _repository.getOrder(params);
}

class GetOpenOrderByTableUseCase implements UseCase<Order?, int> {
  const GetOpenOrderByTableUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order?>> call(int params) =>
      _repository.getOpenOrderByTable(params);
}

class CreateOrderParams {
  const CreateOrderParams({
    required this.type,
    this.tableId,
    this.guestCount = 1,
    this.note,
    required this.lines,
  });

  final String type;
  final int? tableId;
  final int guestCount;
  final String? note;
  final List<CartLine> lines;
}

/// เปิดออเดอร์ใหม่จากตะกร้า
class CreateOrderUseCase implements UseCase<Order, CreateOrderParams> {
  const CreateOrderUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(CreateOrderParams params) =>
      _repository.createOrder(
        type: params.type,
        tableId: params.tableId,
        guestCount: params.guestCount,
        note: params.note,
        items: cartToPayload(params.lines),
      );
}

class AddItemsParams {
  const AddItemsParams({required this.orderId, required this.lines});

  final int orderId;
  final List<CartLine> lines;
}

/// สั่งอาหารเพิ่มในออเดอร์เดิม (สั่งรอบสอง)
class AddOrderItemsUseCase implements UseCase<Order, AddItemsParams> {
  const AddOrderItemsUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(AddItemsParams params) =>
      _repository.addItems(params.orderId, cartToPayload(params.lines));
}

class UpdateOrderItemParams {
  const UpdateOrderItemParams({
    required this.orderId,
    required this.itemId,
    this.quantity,
    this.note,
  });

  final int orderId;
  final int itemId;
  final int? quantity;
  final String? note;
}

class UpdateOrderItemUseCase implements UseCase<Order, UpdateOrderItemParams> {
  const UpdateOrderItemUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(UpdateOrderItemParams params) =>
      _repository.updateItem(
        params.orderId,
        params.itemId,
        quantity: params.quantity,
        note: params.note,
      );
}

class RemoveOrderItemParams {
  const RemoveOrderItemParams({required this.orderId, required this.itemId});

  final int orderId;
  final int itemId;
}

class RemoveOrderItemUseCase implements UseCase<Order, RemoveOrderItemParams> {
  const RemoveOrderItemUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(RemoveOrderItemParams params) =>
      _repository.removeItem(params.orderId, params.itemId);
}

class UpdateItemStatusParams {
  const UpdateItemStatusParams({
    required this.orderId,
    required this.itemId,
    required this.status,
  });

  final int orderId;
  final int itemId;
  final String status;
}

/// อัปเดตสถานะรายการอาหาร — ใช้ทั้งจอครัวและตอนพนักงานกดเสิร์ฟ
class UpdateOrderItemStatusUseCase
    implements UseCase<Order, UpdateItemStatusParams> {
  const UpdateOrderItemStatusUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(UpdateItemStatusParams params) => _repository
      .updateItemStatus(params.orderId, params.itemId, params.status);
}

class SendToKitchenUseCase implements UseCase<Order, int> {
  const SendToKitchenUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(int params) => _repository.sendToKitchen(params);
}

class ApplyDiscountParams {
  const ApplyDiscountParams({
    required this.orderId,
    required this.type,
    required this.value,
  });

  final int orderId;
  final String type;
  final double value;
}

class ApplyDiscountUseCase implements UseCase<Order, ApplyDiscountParams> {
  const ApplyDiscountUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(ApplyDiscountParams params) =>
      _repository.applyDiscount(params.orderId, params.type, params.value);
}

class CancelOrderParams {
  const CancelOrderParams({required this.orderId, required this.reason});

  final int orderId;
  final String reason;
}

class CancelOrderUseCase implements UseCase<Order, CancelOrderParams> {
  const CancelOrderUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(CancelOrderParams params) =>
      _repository.cancelOrder(params.orderId, params.reason);
}

class MoveOrderTableParams {
  const MoveOrderTableParams({required this.orderId, required this.tableId});

  final int orderId;
  final int tableId;
}

/// ย้ายออเดอร์ (ที่ยังไม่ปิดบิล) ไปโต๊ะอื่น เช่น ลูกค้าขอย้ายที่นั่ง
class MoveOrderTableUseCase implements UseCase<Order, MoveOrderTableParams> {
  const MoveOrderTableUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(MoveOrderTableParams params) =>
      _repository.moveTable(params.orderId, params.tableId);
}

class MergeOrdersParams {
  const MergeOrdersParams({
    required this.targetOrderId,
    required this.sourceOrderId,
  });

  final int targetOrderId;
  final int sourceOrderId;
}

/// รวมออเดอร์ต้นทางเข้ากับออเดอร์ปลายทาง — ใช้ตอนลูกค้าขอรวมโต๊ะ/รวมบิล
class MergeOrdersUseCase implements UseCase<Order, MergeOrdersParams> {
  const MergeOrdersUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(MergeOrdersParams params) =>
      _repository.mergeOrders(params.targetOrderId, params.sourceOrderId);
}

/// คิวครัว
class GetKitchenQueueUseCase
    implements UseCase<List<OrderItem>, List<String>?> {
  const GetKitchenQueueUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<List<OrderItem>>> call(List<String>? params) =>
      _repository.getKitchenQueue(statuses: params);
}

class RedeemPromotionCodeParams {
  const RedeemPromotionCodeParams({required this.orderId, required this.code});

  final int orderId;
  final String code;
}

/// กรอกโค้ดส่วนลด — ถ้าเข้าเงื่อนไขจะผูกไว้กับออเดอร์ทันที
class RedeemPromotionCodeUseCase
    implements UseCase<Order, RedeemPromotionCodeParams> {
  const RedeemPromotionCodeUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(RedeemPromotionCodeParams params) =>
      _repository.redeemPromotionCode(params.orderId, params.code);
}

/// เอาโปรโมชันที่ผูกด้วยโค้ดออกจากออเดอร์
class RemovePromotionUseCase implements UseCase<Order, int> {
  const RemovePromotionUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(int params) => _repository.removePromotion(params);
}

/// โปรโมชันทั้งหมดที่เข้าเงื่อนไขกับบิลนี้ตอนนี้
class GetEligiblePromotionsUseCase
    implements UseCase<List<EligiblePromotion>, int> {
  const GetEligiblePromotionsUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<List<EligiblePromotion>>> call(int params) =>
      _repository.getEligiblePromotions(params);
}
