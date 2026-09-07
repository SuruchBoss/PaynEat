import '../../../../core/usecases/result.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../entities/order.dart';
import '../entities/order_item.dart';

abstract class OrderRepository {
  Future<Result<({List<Order> orders, int total})>> getOrders({
    String? status,
    bool? activeOnly,
    String? dateFrom,
    String? dateTo,
    int page,
    int limit,
  });

  Future<Result<Order>> getOrder(int id);
  Future<Result<Order?>> getOpenOrderByTable(int tableId);

  Future<Result<Order>> createOrder({
    required String type,
    int? tableId,
    required int guestCount,
    String? note,
    required List<OrderItemPayload> items,
  });

  Future<Result<Order>> addItems(int orderId, List<OrderItemPayload> items);
  Future<Result<Order>> updateItem(int orderId, int itemId, {int? quantity, String? note});
  Future<Result<Order>> removeItem(int orderId, int itemId);
  Future<Result<Order>> updateItemStatus(int orderId, int itemId, String status);
  Future<Result<Order>> sendToKitchen(int orderId);
  Future<Result<Order>> applyDiscount(int orderId, String type, double value);
  Future<Result<Order>> cancelOrder(int orderId, String reason);
  Future<Result<List<OrderItem>>> getKitchenQueue({List<String>? statuses});
}
