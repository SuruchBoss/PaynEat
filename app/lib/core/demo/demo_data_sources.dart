import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/ingredient/data/datasources/ingredient_remote_data_source.dart';
import '../../features/ingredient/data/models/ingredient_model.dart';
import '../../features/menu/data/datasources/menu_remote_data_source.dart';
import '../../features/menu/data/models/category_model.dart';
import '../../features/menu/data/models/menu_item_model.dart';
import '../../features/menu/domain/entities/menu_item_payload.dart';
import '../../features/order/data/datasources/order_remote_data_source.dart';
import '../../features/order/domain/entities/order_item_payload.dart';
import '../../features/promotion/data/datasources/promotion_remote_data_source.dart';
import '../../features/promotion/data/models/promotion_model.dart';
import '../../features/table/data/datasources/table_remote_data_source.dart';
import '../../features/table/data/models/dining_table_model.dart';
import '../../features/order/data/models/order_model.dart';
import '../../features/payment/data/datasources/payment_remote_data_source.dart';
import '../../features/payment/data/models/payment_model.dart';
import '../../features/payment/domain/entities/payment.dart';
import '../../features/report/data/datasources/report_remote_data_source.dart';
import '../../features/report/data/models/report_model.dart';
import '../../features/report/domain/entities/report.dart';
import '../../features/settings/data/datasources/settings_remote_data_source.dart';
import '../../features/settings/domain/entities/store_settings.dart';
import '../../features/shift/data/datasources/shift_remote_data_source.dart';
import '../../features/shift/data/models/shift_model.dart';
import '../../features/staff/data/datasources/staff_remote_data_source.dart';
import '../constants/app_constants.dart';
import 'demo_store.dart';

/// Data source ชุด "Demo Mode"
///
/// สลับมาใช้ชุดนี้แทนตัวที่ยิง HTTP จริงได้โดยไม่ต้องแก้โค้ดหน้าจอหรือ use case เลย
/// เพราะทุกชั้นบนรู้จักแค่ abstract — เป็นประโยชน์ที่จับต้องได้ของการแยกชั้น
///
/// ใช้ตอน deploy ตัวอย่างผลงานขึ้น static hosting (ไม่มี backend ให้เรียก)
Future<T> _delayed<T>(T Function() action) async {
  await Future<void>.delayed(DemoStore.latency);
  return action();
}

class DemoAuthDataSource implements AuthRemoteDataSource {
  DemoAuthDataSource(this._store);

  final DemoStore _store;
  String? _token;

  @override
  Future<({String token, UserModel user})> login(
    String username,
    String password,
  ) => _delayed(() {
    final result = _store.login(username, password);
    _token = result['token'] as String;
    return (
      token: _token!,
      user: UserModel.fromJson(result['user'] as Map<String, dynamic>),
    );
  });

  @override
  Future<UserModel> getProfile() =>
      _delayed(() => UserModel.fromJson(_store.profile(_token)));

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {}

  /// ใช้หา id ของผู้ใช้ปัจจุบันตอนสร้างออเดอร์/รับเงิน
  int? get currentUserId => int.tryParse(_token?.split('-').last ?? '');
}

class DemoMenuDataSource implements MenuRemoteDataSource {
  const DemoMenuDataSource(this._store);

  final DemoStore _store;

  @override
  Future<List<CategoryModel>> getCategories({bool activeOnly = false}) =>
      _delayed(
        () => _store
            .categoryList()
            .map(CategoryModel.fromJson)
            .toList(growable: false),
      );

  @override
  Future<CategoryModel> createCategory(Map<String, dynamic> body) =>
      _delayed(() => CategoryModel.fromJson(_store.saveCategory(body)));

  @override
  Future<CategoryModel> updateCategory(int id, Map<String, dynamic> body) =>
      _delayed(() => CategoryModel.fromJson(_store.saveCategory(body, id: id)));

  @override
  Future<void> deleteCategory(int id) =>
      _delayed(() => _store.deleteCategory(id));

  @override
  Future<List<MenuItemModel>> getMenuItems({
    int? categoryId,
    String? search,
    bool? availableOnly,
    int page = 1,
    int limit = 200,
  }) => _delayed(
    () => _store
        .menuList(
          categoryId: categoryId,
          search: search,
          availableOnly: availableOnly,
        )
        .map(MenuItemModel.fromJson)
        .toList(growable: false),
  );

  @override
  Future<MenuItemModel> getMenuItem(int id) =>
      _delayed(() => MenuItemModel.fromJson(_store.menuItem(id)));

  @override
  Future<MenuItemModel> createMenuItem(MenuItemPayload payload) => _delayed(
    () => MenuItemModel.fromJson(_store.saveMenuItem(payload.toJson())),
  );

  @override
  Future<MenuItemModel> updateMenuItem(int id, MenuItemPayload payload) =>
      _delayed(
        () => MenuItemModel.fromJson(
          _store.saveMenuItem(payload.toJson(), id: id),
        ),
      );

  @override
  Future<MenuItemModel> setAvailability(int id, bool isAvailable) => _delayed(
    () => MenuItemModel.fromJson(_store.setAvailability(id, isAvailable)),
  );

  @override
  Future<void> deleteMenuItem(int id) =>
      _delayed(() => _store.deleteMenuItem(id));
}

class DemoIngredientDataSource implements IngredientRemoteDataSource {
  const DemoIngredientDataSource(this._store);

  final DemoStore _store;

  @override
  Future<List<IngredientModel>> getIngredients({bool lowStockOnly = false}) =>
      _delayed(
        () => _store
            .ingredientList(lowStockOnly: lowStockOnly)
            .map(IngredientModel.fromJson)
            .toList(growable: false),
      );

  @override
  Future<IngredientModel> getIngredient(int id) =>
      _delayed(() => IngredientModel.fromJson(_store.ingredient(id)));

  @override
  Future<IngredientModel> createIngredient(Map<String, dynamic> body) =>
      _delayed(() => IngredientModel.fromJson(_store.saveIngredient(body)));

  @override
  Future<IngredientModel> updateIngredient(int id, Map<String, dynamic> body) =>
      _delayed(
        () => IngredientModel.fromJson(_store.saveIngredient(body, id: id)),
      );

  @override
  Future<IngredientModel> adjustStock(int id, double delta) => _delayed(
    () => IngredientModel.fromJson(_store.adjustIngredientStock(id, delta)),
  );

  @override
  Future<void> deleteIngredient(int id) =>
      _delayed(() => _store.deleteIngredient(id));
}

class DemoTableDataSource implements TableRemoteDataSource {
  const DemoTableDataSource(this._store);

  final DemoStore _store;

  @override
  Future<List<DiningTableModel>> getTables({String? zone, String? status}) =>
      _delayed(
        () => _store
            .tableList(zone: zone, status: status)
            .map(DiningTableModel.fromJson)
            .toList(growable: false),
      );

  @override
  Future<List<String>> getZones() => _delayed(() => _store.zones());

  @override
  Future<DiningTableModel> setStatus(int id, String status) => _delayed(
    () => DiningTableModel.fromJson(_store.setTableStatus(id, status)),
  );

  @override
  Future<DiningTableModel> create(Map<String, dynamic> body) =>
      _delayed(() => DiningTableModel.fromJson(_store.saveTable(body)));

  @override
  Future<DiningTableModel> update(int id, Map<String, dynamic> body) =>
      _delayed(() => DiningTableModel.fromJson(_store.saveTable(body, id: id)));

  @override
  Future<void> delete(int id) => _delayed(() => _store.deleteTable(id));
}

class DemoOrderDataSource implements OrderRemoteDataSource {
  DemoOrderDataSource(this._store, this._auth);

  final DemoStore _store;
  final DemoAuthDataSource _auth;

  @override
  Future<({List<OrderModel> orders, int total})> getOrders({
    String? status,
    bool? activeOnly,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 30,
  }) => _delayed(() {
    final rows = _store.orderList(
      status: status,
      activeOnly: activeOnly,
      dateFrom: dateFrom,
    );
    return (
      orders: rows.take(limit).map(OrderModel.fromJson).toList(growable: false),
      total: rows.length,
    );
  });

  @override
  Future<OrderModel> getOrder(int id) =>
      _delayed(() => OrderModel.fromJson(_store.findOrder(id)));

  @override
  Future<OrderModel?> getOpenOrderByTable(int tableId) => _delayed(() {
    final order = _store.openOrderByTable(tableId);
    return order == null ? null : OrderModel.fromJson(order);
  });

  @override
  Future<OrderModel> createOrder({
    required String type,
    int? tableId,
    int guestCount = 1,
    String? note,
    required List<OrderItemPayload> items,
  }) => _delayed(
    () => OrderModel.fromJson(
      _store.createOrder(
        type: type,
        tableId: tableId,
        guestCount: guestCount,
        waiterId: _auth.currentUserId,
        items: items.map((item) => item.toJson()).toList(growable: false),
      ),
    ),
  );

  @override
  Future<OrderModel> addItems(int orderId, List<OrderItemPayload> items) =>
      _delayed(
        () => OrderModel.fromJson(
          _store.addItems(
            orderId,
            items.map((item) => item.toJson()).toList(growable: false),
          ),
        ),
      );

  @override
  Future<OrderModel> updateItem(
    int orderId,
    int itemId, {
    int? quantity,
    String? note,
  }) => _delayed(
    () => OrderModel.fromJson(
      _store.updateItem(orderId, itemId, quantity: quantity, note: note),
    ),
  );

  @override
  Future<OrderModel> removeItem(int orderId, int itemId) =>
      _delayed(() => OrderModel.fromJson(_store.removeItem(orderId, itemId)));

  @override
  Future<OrderModel> updateItemStatus(int orderId, int itemId, String status) =>
      _delayed(
        () => OrderModel.fromJson(
          _store.updateItemStatus(orderId, itemId, status),
        ),
      );

  @override
  Future<OrderModel> sendToKitchen(int orderId) =>
      _delayed(() => OrderModel.fromJson(_store.sendToKitchen(orderId)));

  @override
  Future<OrderModel> applyDiscount(int orderId, String type, double value) =>
      _delayed(
        () => OrderModel.fromJson(_store.applyDiscount(orderId, type, value)),
      );

  @override
  Future<OrderModel> cancelOrder(int orderId, String reason) =>
      _delayed(() => OrderModel.fromJson(_store.cancelOrder(orderId, reason)));

  @override
  Future<OrderModel> moveTable(int orderId, int tableId) => _delayed(
    () => OrderModel.fromJson(_store.moveOrderTable(orderId, tableId)),
  );

  @override
  Future<OrderModel> mergeOrders(int targetOrderId, int sourceOrderId) =>
      _delayed(
        () => OrderModel.fromJson(
          _store.mergeOrders(targetOrderId, sourceOrderId),
        ),
      );

  @override
  Future<List<OrderItemModel>> getKitchenQueue({List<String>? statuses}) =>
      _delayed(
        () => _store
            .kitchenQueue(
              statuses ??
                  const [
                    OrderItemStatus.pending,
                    OrderItemStatus.cooking,
                    OrderItemStatus.ready,
                  ],
            )
            .map(OrderItemModel.fromJson)
            .toList(growable: false),
      );

  @override
  Future<OrderModel> redeemPromotionCode(int orderId, String code) => _delayed(
    () => OrderModel.fromJson(_store.redeemPromotionCode(orderId, code)),
  );

  @override
  Future<OrderModel> removePromotion(int orderId) =>
      _delayed(() => OrderModel.fromJson(_store.removePromotion(orderId)));

  @override
  Future<List<EligiblePromotionModel>> getEligiblePromotions(int orderId) =>
      _delayed(
        () => _store
            .eligiblePromotions(orderId)
            .map(EligiblePromotionModel.fromJson)
            .toList(growable: false),
      );
}

class DemoPromotionDataSource implements PromotionRemoteDataSource {
  const DemoPromotionDataSource(this._store);

  final DemoStore _store;

  @override
  Future<List<PromotionModel>> getPromotions({bool activeOnly = false}) =>
      _delayed(
        () => _store
            .promotionList(activeOnly: activeOnly)
            .map(PromotionModel.fromJson)
            .toList(growable: false),
      );

  @override
  Future<PromotionModel> getPromotion(int id) =>
      _delayed(() => PromotionModel.fromJson(_store.promotion(id)));

  @override
  Future<PromotionModel> createPromotion(Map<String, dynamic> body) =>
      _delayed(() => PromotionModel.fromJson(_store.savePromotion(body)));

  @override
  Future<PromotionModel> updatePromotion(int id, Map<String, dynamic> body) =>
      _delayed(
        () => PromotionModel.fromJson(_store.savePromotion(body, id: id)),
      );

  @override
  Future<void> deletePromotion(int id) =>
      _delayed(() => _store.deletePromotion(id));
}

class DemoPaymentDataSource implements PaymentRemoteDataSource {
  DemoPaymentDataSource(this._store, this._auth);

  final DemoStore _store;
  final DemoAuthDataSource _auth;

  @override
  Future<({PaymentResult result, OrderModel order})> pay({
    required int orderId,
    required String method,
    double? amount,
    List<int>? itemIds,
    double? received,
    String? reference,
  }) => _delayed(() {
    final data = _store.pay(
      orderId: orderId,
      method: method,
      amount: amount,
      itemIds: itemIds,
      received: received,
      reference: reference,
      cashierId: _auth.currentUserId,
    );
    return (
      result: PaymentResult(
        payment: PaymentModel.fromJson(data['payment'] as Map<String, dynamic>),
        isFullyPaid: data['isFullyPaid'] as bool,
        remaining: (data['remaining'] as num).toDouble(),
      ),
      order: OrderModel.fromJson(data['order'] as Map<String, dynamic>),
    );
  });

  @override
  Future<PaymentSummaryModel> getSummary(int orderId) => _delayed(
    () => PaymentSummaryModel.fromJson(_store.paymentSummary(orderId)),
  );

  @override
  Future<SplitPreviewModel> getSplitPreview(int orderId, List<int> itemIds) =>
      _delayed(
        () => SplitPreviewModel.fromJson(_store.splitPreview(orderId, itemIds)),
      );

  @override
  Future<({Receipt receipt, OrderModel order})> getReceipt(int orderId) =>
      _delayed(() {
        final data = _store.receipt(orderId);
        final store = data['store'] as Map<String, dynamic>;
        return (
          receipt: Receipt(
            storeName: store['name'] as String,
            currency: store['currency'] as String,
            vatRate: (store['vatRate'] as num).toDouble(),
            serviceChargeRate: (store['serviceChargeRate'] as num).toDouble(),
            paidAt: data['paidAt'] as String?,
            changeTotal: (data['changeTotal'] as num).toDouble(),
            payments: (data['payments'] as List)
                .cast<Map<String, dynamic>>()
                .map(PaymentModel.fromJson)
                .toList(growable: false),
            refunds: (data['refunds'] as List)
                .cast<Map<String, dynamic>>()
                .map(RefundModel.fromJson)
                .toList(growable: false),
            refundedTotal: (data['refundedTotal'] as num).toDouble(),
          ),
          order: OrderModel.fromJson(data['order'] as Map<String, dynamic>),
        );
      });

  @override
  Future<RefundModel> refund({
    required int paymentId,
    required double amount,
    required String reason,
  }) => _delayed(
    () => RefundModel.fromJson(
      _store.refundPayment(
        paymentId: paymentId,
        amount: amount,
        reason: reason,
        refundedById: _auth.currentUserId ?? 0,
      ),
    ),
  );
}

class DemoShiftDataSource implements ShiftRemoteDataSource {
  const DemoShiftDataSource(this._store, this._auth);

  final DemoStore _store;
  final DemoAuthDataSource _auth;

  @override
  Future<ShiftModel?> getCurrent() => _delayed(() {
    final data = _store.currentShift();
    return data == null ? null : ShiftModel.fromJson(data);
  });

  @override
  Future<ShiftModel> open(double openingCash) => _delayed(
    () => ShiftModel.fromJson(
      _store.openShift(
        openingCash: openingCash,
        openedById: _auth.currentUserId ?? 0,
      ),
    ),
  );

  @override
  Future<ShiftModel> close(
    int id, {
    required double countedCash,
    String? note,
  }) => _delayed(
    () => ShiftModel.fromJson(
      _store.closeShift(
        id,
        countedCash: countedCash,
        note: note,
        closedById: _auth.currentUserId ?? 0,
      ),
    ),
  );

  @override
  Future<List<ShiftModel>> getHistory() =>
      _delayed(() => _store.shiftHistory().map(ShiftModel.fromJson).toList());
}

class DemoReportDataSource implements ReportRemoteDataSource {
  const DemoReportDataSource(this._store);

  final DemoStore _store;

  @override
  Future<DashboardData> getDashboard() =>
      _delayed(() => ReportMapper.dashboardFromJson(_store.dashboard()));

  @override
  Future<SalesSummary> getSummary({String? from, String? to}) => _delayed(
    () => ReportMapper.summaryFromJson(_store.salesSummary(from: from, to: to)),
  );

  @override
  Future<List<TopItem>> getTopItems({
    String? from,
    String? to,
    int limit = 10,
  }) => _delayed(
    () => _store
        .topItems(from: from, to: to, limit: limit)
        .map(ReportMapper.topItemFromJson)
        .toList(growable: false),
  );

  @override
  Future<List<DailySales>> getSalesByDay({String? from, String? to}) =>
      _delayed(
        () => _store
            .salesByDay(from: from, to: to)
            .map(ReportMapper.dailyFromJson)
            .toList(growable: false),
      );
}

class DemoStaffDataSource implements StaffRemoteDataSource {
  const DemoStaffDataSource(this._store);

  final DemoStore _store;

  @override
  Future<List<UserModel>> getStaff({String? role}) => _delayed(
    () => _store
        .staff()
        .where((user) => role == null || user['role'] == role)
        .map(UserModel.fromJson)
        .toList(growable: false),
  );

  @override
  Future<UserModel> create({
    required String name,
    required String username,
    required String password,
    required String role,
  }) => _delayed(
    () => UserModel.fromJson(
      _store.createStaff(
        name: name,
        username: username,
        password: password,
        role: role,
      ),
    ),
  );

  @override
  Future<UserModel> update(int id, Map<String, dynamic> changes) =>
      _delayed(() => UserModel.fromJson(_store.updateStaff(id, changes)));

  @override
  Future<UserModel> resetPassword(int id, String password) => _delayed(
    () => UserModel.fromJson(_store.updateStaff(id, {'password': password})),
  );

  @override
  Future<void> delete(int id) => _delayed(() => _store.deleteStaff(id));
}

class DemoSettingsDataSource implements SettingsRemoteDataSource {
  const DemoSettingsDataSource(this._store);

  final DemoStore _store;

  StoreSettings _map(Map<String, dynamic> json) => StoreSettings(
    storeName: json['storeName'] as String,
    currency: json['currency'] as String,
    vatRate: (json['vatRate'] as num).toDouble(),
    serviceChargeRate: (json['serviceChargeRate'] as num).toDouble(),
    vatIncluded: json['vatIncluded'] as bool,
  );

  @override
  Future<StoreSettings> get() => _delayed(() => _map(_store.settings));

  @override
  Future<StoreSettings> update(Map<String, dynamic> changes) => _delayed(() {
    changes.forEach((key, value) => _store.settings[key] = value);
    return _map(_store.settings);
  });
}
