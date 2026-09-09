import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/offline_order_queue_service.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/domain/entities/menu_option.dart';
import '../../../settings/domain/entities/store_settings.dart';
import '../../../settings/domain/usecases/settings_usecases.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/services/bill_calculator.dart';
import '../../domain/usecases/order_usecases.dart';

/// ตะกร้าสำหรับ "รับออเดอร์" — ใช้ได้ทั้งเปิดออเดอร์ใหม่และสั่งเพิ่มในออเดอร์เดิม
///
/// ตะกร้าอยู่ในเครื่องจนกว่าจะกดยืนยัน ทำให้พนักงานแก้ไขได้เร็วโดยไม่ยิง API รัว ๆ
class CartController extends GetxController {
  CartController({
    required CreateOrderUseCase createOrder,
    required AddOrderItemsUseCase addItems,
    required SendToKitchenUseCase sendToKitchen,
    required GetSettingsUseCase getSettings,
    required OfflineOrderQueueService offlineQueue,
  }) : _createOrder = createOrder,
       _addItems = addItems,
       _sendToKitchen = sendToKitchen,
       _getSettings = getSettings,
       _offlineQueue = offlineQueue;

  final CreateOrderUseCase _createOrder;
  final AddOrderItemsUseCase _addItems;
  final SendToKitchenUseCase _sendToKitchen;
  final GetSettingsUseCase _getSettings;
  final OfflineOrderQueueService _offlineQueue;

  final RxList<CartLine> lines = <CartLine>[].obs;
  final RxBool isSubmitting = false.obs;
  final RxInt guestCount = 1.obs;
  final RxString orderType = OrderType.dineIn.obs;
  final Rx<StoreSettings> settings = StoreSettings.fallback.obs;

  /// ถ้ามาจากโต๊ะ จะมี tableId; ถ้าเป็นการสั่งเพิ่ม จะมี existingOrderId
  int? tableId;
  String? tableName;
  int? existingOrderId;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args is Map) {
      tableId = args['tableId'] as int?;
      tableName = args['tableName'] as String?;
      existingOrderId = args['orderId'] as int?;
      final seats = args['seats'] as int?;
      if (seats != null) guestCount.value = seats.clamp(1, 50);
      if (tableId == null && existingOrderId == null) {
        orderType.value = OrderType.takeaway;
      }
    }

    _loadSettings();
  }

  bool get isAddingToExistingOrder => existingOrderId != null;
  bool get isEmpty => lines.isEmpty;
  int get totalQuantity => lines.fold(0, (sum, line) => sum + line.quantity);
  double get subtotal => lines.fold(0, (sum, line) => sum + line.lineTotal);

  /// ตัวอย่างยอดบิล คำนวณด้วยกฎเดียวกับ backend
  BillBreakdown get preview => BillCalculator(
    vatRate: settings.value.vatRate,
    serviceChargeRate: settings.value.serviceChargeRate,
    vatIncluded: settings.value.vatIncluded,
  ).fromCart(lines);

  Future<void> _loadSettings() async {
    final result = await _getSettings();
    result.fold(
      onSuccess: (data) => settings.value = data,
      onFailure: (_) {}, // ใช้ค่า fallback ต่อไปได้ ไม่ต้องรบกวนผู้ใช้
    );
  }

  /// เพิ่มลงตะกร้า — ถ้ารายการเหมือนกันทุกอย่างให้เพิ่มจำนวนแทนการสร้างบรรทัดใหม่
  void addItem(
    MenuItem menuItem, {
    int quantity = 1,
    List<MenuOption> options = const [],
    String? note,
  }) {
    final candidate = CartLine(
      menuItem: menuItem,
      quantity: quantity,
      selectedOptions: List<MenuOption>.from(options),
      note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
    );

    final index = lines.indexWhere(
      (line) => line.signature == candidate.signature,
    );
    if (index >= 0) {
      lines[index].quantity += quantity;
      lines.refresh();
    } else {
      lines.add(candidate);
    }
  }

  void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= lines.length) return;
    if (quantity <= 0) {
      lines.removeAt(index);
      return;
    }
    lines[index].quantity = quantity;
    lines.refresh();
  }

  void updateNote(int index, String? note) {
    if (index < 0 || index >= lines.length) return;
    lines[index].note = (note?.trim().isEmpty ?? true) ? null : note!.trim();
    lines.refresh();
  }

  void removeAt(int index) => lines.removeAt(index);

  void clear() => lines.clear();

  void setGuestCount(int value) => guestCount.value = value.clamp(1, 50);

  void setOrderType(String value) => orderType.value = value;

  /// ยืนยันออเดอร์
  /// [sendToKitchenNow] = true จะส่งเข้าครัวทันทีในขั้นตอนเดียว
  Future<void> submit({bool sendToKitchenNow = true}) async {
    if (lines.isEmpty) {
      AppDialogs.info('ยังไม่ได้เลือกรายการอาหาร');
      return;
    }

    isSubmitting.value = true;

    final result = isAddingToExistingOrder
        ? await _addItems(
            AddItemsParams(orderId: existingOrderId!, lines: lines.toList()),
          )
        : await _createOrder(
            CreateOrderParams(
              type: orderType.value,
              tableId: tableId,
              guestCount: guestCount.value,
              lines: lines.toList(),
            ),
          );

    await result.fold(
      onSuccess: (order) async {
        if (sendToKitchenNow && order.status == OrderStatus.open) {
          await _sendToKitchen(order.id);
        }
        isSubmitting.value = false;
        clear();
        AppDialogs.success(
          isAddingToExistingOrder
              ? 'เพิ่มรายการเข้าออเดอร์ ${order.code} แล้ว'
              : 'เปิดออเดอร์ ${order.code} เรียบร้อย',
        );
        Get.offNamed<void>(
          AppRoutes.orderDetail,
          arguments: {'orderId': order.id},
        );
      },
      onFailure: (failure) async {
        isSubmitting.value = false;

        // สั่งเพิ่มเข้าออเดอร์เดิมที่พังเพราะเน็ตหลุด (ไม่ใช่เปิดออเดอร์ใหม่ — ความเสี่ยง
        // conflict สูงกว่า จึงยังไม่รองรับออฟไลน์ ดู docs/DECISIONS.md) ให้ queue รายการไว้
        // ในเครื่องแทนที่จะบล็อกพนักงาน แล้วส่งขึ้นเซิร์ฟเวอร์อัตโนมัติเมื่อเน็ตกลับมา
        if (isAddingToExistingOrder && failure is NetworkFailure) {
          final queuedLines = lines.toList();
          await _offlineQueue.enqueue(
            orderId: existingOrderId!,
            orderLabel: tableName != null
                ? 'โต๊ะ $tableName'
                : 'ออเดอร์ #$existingOrderId',
            items: cartToPayload(queuedLines),
            summary: queuedLines
                .map((line) => '${line.menuItem.name} x${line.quantity}')
                .join(', '),
          );
          clear();
          AppDialogs.info(
            'ออฟไลน์ — บันทึกรายการไว้ในเครื่องแล้ว จะส่งเข้าระบบอัตโนมัติเมื่อเน็ตกลับมา',
          );
          Get.back<void>();
          return;
        }

        AppDialogs.error(failure.message);
      },
    );
  }
}
