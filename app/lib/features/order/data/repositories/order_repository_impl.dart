import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/entities/order_item_payload.dart';
import '../datasources/order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._remote);

  final OrderRemoteDataSource _remote;

  @override
  Future<Result<({List<Order> orders, int total})>> getOrders({
    String? status,
    bool? activeOnly,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 30,
  }) => guard(() async {
    final result = await _remote.getOrders(
      status: status,
      activeOnly: activeOnly,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
      limit: limit,
    );
    return (orders: result.orders.cast<Order>(), total: result.total);
  });

  @override
  Future<Result<Order>> getOrder(int id) =>
      guard(() async => await _remote.getOrder(id));

  @override
  Future<Result<Order?>> getOpenOrderByTable(int tableId) =>
      guard(() async => await _remote.getOpenOrderByTable(tableId));

  @override
  Future<Result<Order>> createOrder({
    required String type,
    int? tableId,
    required int guestCount,
    String? note,
    required List<OrderItemPayload> items,
  }) => guard(
    () async => await _remote.createOrder(
      type: type,
      tableId: tableId,
      guestCount: guestCount,
      note: note,
      items: items,
    ),
  );

  @override
  Future<Result<Order>> addItems(int orderId, List<OrderItemPayload> items) =>
      guard(() async => await _remote.addItems(orderId, items));

  @override
  Future<Result<Order>> updateItem(
    int orderId,
    int itemId, {
    int? quantity,
    String? note,
  }) => guard(
    () async => await _remote.updateItem(
      orderId,
      itemId,
      quantity: quantity,
      note: note,
    ),
  );

  @override
  Future<Result<Order>> removeItem(int orderId, int itemId) =>
      guard(() async => await _remote.removeItem(orderId, itemId));

  @override
  Future<Result<Order>> updateItemStatus(
    int orderId,
    int itemId,
    String status,
  ) => guard(
    () async => await _remote.updateItemStatus(orderId, itemId, status),
  );

  @override
  Future<Result<Order>> sendToKitchen(int orderId) =>
      guard(() async => await _remote.sendToKitchen(orderId));

  @override
  Future<Result<Order>> applyDiscount(int orderId, String type, double value) =>
      guard(() async => await _remote.applyDiscount(orderId, type, value));

  @override
  Future<Result<Order>> cancelOrder(int orderId, String reason) =>
      guard(() async => await _remote.cancelOrder(orderId, reason));

  @override
  Future<Result<Order>> moveTable(int orderId, int tableId) =>
      guard(() async => await _remote.moveTable(orderId, tableId));

  @override
  Future<Result<Order>> mergeOrders(int targetOrderId, int sourceOrderId) =>
      guard(
        () async => await _remote.mergeOrders(targetOrderId, sourceOrderId),
      );

  @override
  Future<Result<List<OrderItem>>> getKitchenQueue({List<String>? statuses}) =>
      guard(() async => await _remote.getKitchenQueue(statuses: statuses));
}
