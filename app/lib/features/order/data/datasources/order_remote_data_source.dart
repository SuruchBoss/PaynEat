import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/order_item_payload.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<({List<OrderModel> orders, int total})> getOrders({
    String? status,
    bool? activeOnly,
    String? dateFrom,
    String? dateTo,
    int page,
    int limit,
  });
  Future<OrderModel> getOrder(int id);
  Future<OrderModel?> getOpenOrderByTable(int tableId);
  Future<OrderModel> createOrder({
    required String type,
    int? tableId,
    int guestCount,
    String? note,
    required List<OrderItemPayload> items,
  });
  Future<OrderModel> addItems(int orderId, List<OrderItemPayload> items);
  Future<OrderModel> updateItem(
    int orderId,
    int itemId, {
    int? quantity,
    String? note,
  });
  Future<OrderModel> removeItem(int orderId, int itemId);
  Future<OrderModel> updateItemStatus(int orderId, int itemId, String status);
  Future<OrderModel> sendToKitchen(int orderId);
  Future<OrderModel> applyDiscount(int orderId, String type, double value);
  Future<OrderModel> cancelOrder(int orderId, String reason);
  Future<List<OrderItemModel>> getKitchenQueue({List<String>? statuses});
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  const OrderRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<({List<OrderModel> orders, int total})> getOrders({
    String? status,
    bool? activeOnly,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 30,
  }) async {
    final result = await _client.get(
      ApiEndpoints.orders,
      query: {
        'page': page,
        'limit': limit,
        'status': ?status,
        if (activeOnly == true) 'activeOnly': 'true',
        'dateFrom': ?dateFrom,
        'dateTo': ?dateTo,
      },
    );
    return (
      orders: result.asList.map(OrderModel.fromJson).toList(growable: false),
      total: result.total,
    );
  }

  @override
  Future<OrderModel> getOrder(int id) async {
    final result = await _client.get(ApiEndpoints.order(id));
    return OrderModel.fromJson(result.asMap);
  }

  @override
  Future<OrderModel?> getOpenOrderByTable(int tableId) async {
    final result = await _client.get(ApiEndpoints.openOrderByTable(tableId));
    if (result.data == null) return null;
    return OrderModel.fromJson(result.asMap);
  }

  @override
  Future<OrderModel> createOrder({
    required String type,
    int? tableId,
    int guestCount = 1,
    String? note,
    required List<OrderItemPayload> items,
  }) async {
    final result = await _client.post(
      ApiEndpoints.orders,
      body: {
        'type': type,
        'tableId': ?tableId,
        'guestCount': guestCount,
        if (note != null && note.isNotEmpty) 'note': note,
        'items': items.map((item) => item.toJson()).toList(growable: false),
      },
    );
    return OrderModel.fromJson(result.asMap);
  }

  @override
  Future<OrderModel> addItems(int orderId, List<OrderItemPayload> items) async {
    final result = await _client.post(
      ApiEndpoints.orderItems(orderId),
      body: {
        'items': items.map((item) => item.toJson()).toList(growable: false),
      },
    );
    return OrderModel.fromJson(result.asMap);
  }

  @override
  Future<OrderModel> updateItem(
    int orderId,
    int itemId, {
    int? quantity,
    String? note,
  }) async {
    final result = await _client.patch(
      ApiEndpoints.orderItem(orderId, itemId),
      body: {'quantity': ?quantity, 'note': ?note},
    );
    return OrderModel.fromJson(result.asMap);
  }

  @override
  Future<OrderModel> removeItem(int orderId, int itemId) async {
    final result = await _client.delete(
      ApiEndpoints.orderItem(orderId, itemId),
    );
    return OrderModel.fromJson(result.asMap);
  }

  @override
  Future<OrderModel> updateItemStatus(
    int orderId,
    int itemId,
    String status,
  ) async {
    final result = await _client.patch(
      ApiEndpoints.orderItemStatus(orderId, itemId),
      body: {'status': status},
    );
    return OrderModel.fromJson(result.asMap);
  }

  @override
  Future<OrderModel> sendToKitchen(int orderId) async {
    final result = await _client.post(ApiEndpoints.sendToKitchen(orderId));
    return OrderModel.fromJson(result.asMap);
  }

  @override
  Future<OrderModel> applyDiscount(
    int orderId,
    String type,
    double value,
  ) async {
    final result = await _client.post(
      ApiEndpoints.orderDiscount(orderId),
      body: {'type': type, 'value': value},
    );
    return OrderModel.fromJson(result.asMap);
  }

  @override
  Future<OrderModel> cancelOrder(int orderId, String reason) async {
    final result = await _client.post(
      ApiEndpoints.cancelOrder(orderId),
      body: {'reason': reason},
    );
    return OrderModel.fromJson(result.asMap);
  }

  @override
  Future<List<OrderItemModel>> getKitchenQueue({List<String>? statuses}) async {
    final result = await _client.get(
      ApiEndpoints.kitchenQueue,
      query: {
        if (statuses != null && statuses.isNotEmpty)
          'status': statuses.join(','),
      },
    );
    return result.asList.map(OrderItemModel.fromJson).toList(growable: false);
  }
}
