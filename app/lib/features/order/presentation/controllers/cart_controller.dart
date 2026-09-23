import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/offline_order_queue_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/domain/entities/menu_option.dart';
import '../../../settings/domain/entities/store_settings.dart';
import '../../../settings/domain/usecases/settings_usecases.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/services/barcode_resolver.dart';
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

  /// ลูกค้าที่ผูกกับออเดอร์นี้ (optional) — ผูกได้เฉพาะตอนเปิดออเดอร์ใหม่เท่านั้น
  /// เพราะ backend รับ customerId แค่ตอน create order ไม่รองรับตอนสั่งเพิ่ม
  final Rxn<Customer> selectedCustomer = Rxn<Customer>();

  void selectCustomer(Customer customer) => selectedCustomer.value = customer;

  void clearCustomer() => selectedCustomer.value = null;

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
    }
    // มาจากปุ่ม "สั่งกลับบ้าน/เดลิเวอรี่" โดยตรง (ไม่ผ่านการแตะโต๊ะ) — ไม่มี arguments เลยก็ต้อง
    // ตกเป็นค่าเริ่มต้นนี้ด้วย ไม่ใช่แค่ตอน args เป็น Map ถึงจะเช็ค
    if (tableId == null && existingOrderId == null) {
      orderType.value = OrderType.takeaway;
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

  /// ใส่สินค้าขายตามน้ำหนักที่ชั่งแล้ว — บรรทัดใหม่เสมอ ไม่รวมกับถุงก่อนหน้า (ดู CartLine.signature)
  void addWeighedItem(
    MenuItem menuItem,
    int weightGrams, {
    List<MenuOption> options = const [],
    String? note,
  }) {
    lines.add(
      CartLine(
        menuItem: menuItem,
        weightGrams: weightGrams,
        selectedOptions: List<MenuOption>.from(options),
        note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
      ),
    );
  }

  /// ชั่งใหม่ก่อนส่ง (กรอกผิด/เพิ่มของในถุง) — แก้ได้เฉพาะในตะกร้า หลังส่งแล้วต้องลบแล้วชั่งใหม่
  void updateWeight(int index, int weightGrams) {
    if (index < 0 || index >= lines.length) return;
    if (!lines[index].isWeighed || weightGrams <= 0) return;
    lines[index].weightGrams = weightGrams;
    lines.refresh();
  }

  /// รหัสจากเครื่องสแกนบาร์โค้ด (ดู docs/tickets/19-barcode-scale.md) — ใส่ตะกร้าให้เลยถ้าไม่ต้อง
  /// ถามอะไรเพิ่ม ส่วนกรณีที่ต้องเลือกตัวเลือก/ชั่งน้ำหนัก/แจ้งเตือน คืนผลให้หน้าจอจัดการต่อ
  ScanResult applyScan(String code, List<MenuItem> menu) {
    final result = BarcodeResolver.resolve(
      code,
      menu,
      format: ScaleLabelFormat(
        prefix: settings.value.scaleLabelPrefix,
        pluDigits: settings.value.scaleLabelPluDigits,
      ),
    );
    switch (result) {
      case ScannedUnitItem(:final item) when !item.requiresSelection:
        addItem(item);
      case ScannedWeighedItem(:final item, :final weightGrams)
          when !item.requiresSelection:
        addWeighedItem(item, weightGrams);
      default:
        break;
    }
    return result;
  }

  void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= lines.length) return;
    if (quantity <= 0) {
      lines.removeAt(index);
      return;
    }
    // สินค้าชั่งน้ำหนักเป็นบรรทัดละ 1 ถุงเสมอ — เพิ่มถุงต้องชั่งใหม่เป็นอีกบรรทัด
    if (lines[index].isWeighed) return;
    lines[index].quantity = quantity;
    lines.refresh();
  }

  void updateNote(int index, String? note) {
    if (index < 0 || index >= lines.length) return;
    lines[index].note = (note?.trim().isEmpty ?? true) ? null : note!.trim();
    lines.refresh();
  }

  void removeAt(int index) => lines.removeAt(index);

  void clear() {
    lines.clear();
    selectedCustomer.value = null;
  }

  void setGuestCount(int value) => guestCount.value = value.clamp(1, 50);

  void setOrderType(String value) => orderType.value = value;

  /// ยืนยันออเดอร์
  /// [sendToKitchenNow] = true จะส่งเข้าครัวทันทีในขั้นตอนเดียว
  Future<void> submit({bool sendToKitchenNow = true}) async {
    if (lines.isEmpty) {
      AppDialogs.info('order_no_items_selected'.tr);
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
              customerId: selectedCustomer.value?.id,
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
              ? 'order_add_items_success'.trParams({'code': order.code})
              : order.queueNumber != null
              ? 'order_create_success_with_queue'.trParams({
                  'code': order.code,
                  'queue': '${order.queueNumber}',
                })
              : 'order_create_success'.trParams({'code': order.code}),
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
                ? 'order_table_prefix'.trParams({'table': tableName!})
                : 'order_number_prefix'.trParams({
                    'id': existingOrderId!.toString(),
                  }),
            items: cartToPayload(queuedLines),
            summary: queuedLines
                .map(
                  (line) => line.isWeighed
                      ? '${line.menuItem.displayName} ${Formatters.weight(line.weightGrams!)}'
                      : '${line.menuItem.displayName} x${line.quantity}',
                )
                .join(', '),
          );
          clear();
          AppDialogs.info('order_offline_queued_message'.tr);
          Get.back<void>();
          return;
        }

        AppDialogs.error(failure.message);
      },
    );
  }
}
