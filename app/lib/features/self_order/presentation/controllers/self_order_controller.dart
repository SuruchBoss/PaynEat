import 'package:get/get.dart';

import '../../../../core/widgets/app_dialogs.dart';
import '../../../menu/domain/entities/category.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../order/domain/entities/order.dart';
import '../../../order/presentation/widgets/option_selection_sheet.dart';
import '../../domain/entities/self_order_table.dart';
import '../../domain/usecases/add_self_order_items_usecase.dart';
import '../../domain/usecases/get_self_order_menu_usecase.dart';
import '../../domain/usecases/get_self_order_table_usecase.dart';
import 'self_order_cart_line.dart';

/// คุมหน้าสั่งอาหารเองผ่าน QR ทั้งหน้า (ดู docs/tickets/17-qr-self-order.md) — ไม่พึ่ง
/// SessionService/AuthController เลยแม้แต่น้อย เพราะลูกค้าไม่ได้ login
class SelfOrderController extends GetxController {
  SelfOrderController({
    required GetSelfOrderTableUseCase getTableUseCase,
    required GetSelfOrderMenuUseCase getMenuUseCase,
    required AddSelfOrderItemsUseCase addItemsUseCase,
  }) : _getTable = getTableUseCase,
       _getMenu = getMenuUseCase,
       _addItems = addItemsUseCase;

  final GetSelfOrderTableUseCase _getTable;
  final GetSelfOrderMenuUseCase _getMenu;
  final AddSelfOrderItemsUseCase _addItems;

  late final String qrToken;

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<SelfOrderTable> table = Rxn<SelfOrderTable>();
  final Rxn<Order> currentOrder = Rxn<Order>();
  final RxList<Category> categories = <Category>[].obs;
  final RxList<MenuItem> items = <MenuItem>[].obs;
  final RxnInt selectedCategoryId = RxnInt();

  final RxList<SelfOrderCartLine> cart = <SelfOrderCartLine>[].obs;
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    // route ลงทะเบียนเป็น /order/:qrToken (ดู app_routes.dart/app_pages.dart) — อ่านครั้งเดียว
    // ตอนสร้าง controller เพราะหน้านี้ผูกกับโต๊ะเดียวตลอดอายุของมัน ไม่มีการเปลี่ยนโต๊ะกลางคัน
    qrToken = Get.parameters['qrToken'] ?? '';
    load();
  }

  List<MenuItem> get filteredItems {
    final categoryId = selectedCategoryId.value;
    if (categoryId == null) return items;
    return items
        .where((item) => item.categoryId == categoryId)
        .toList(growable: false);
  }

  int get cartItemCount => cart.fold(0, (sum, line) => sum + line.quantity);

  double get cartSubtotalPreview =>
      cart.fold(0.0, (sum, line) => sum + line.lineTotal);

  Future<void> load() async {
    if (qrToken.isEmpty) {
      errorMessage.value = 'self_order_invalid_link'.tr;
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    final tableResult = await _getTable(qrToken);
    final failure = tableResult.failureOrNull;
    if (failure != null) {
      errorMessage.value = failure.message;
      isLoading.value = false;
      return;
    }

    final tableData = tableResult.dataOrNull!;
    table.value = tableData.table;
    currentOrder.value = tableData.order;

    final menuResult = await _getMenu(qrToken);
    menuResult.fold(
      onSuccess: (data) {
        categories.assignAll(data.categories);
        items.assignAll(data.items);
      },
      onFailure: (menuFailure) => errorMessage.value = menuFailure.message,
    );

    isLoading.value = false;
  }

  void selectCategory(int? categoryId) => selectedCategoryId.value = categoryId;

  /// มีตัวเลือกให้เลือก → เปิดแผ่นเลือกก่อน, ไม่มี → ใส่ตะกร้าเลย 1 ที่ (ดู
  /// order_taking_page.dart#_addToCart — ตรรกะเดียวกัน)
  Future<void> addToCart(MenuItem item) async {
    if (!item.requiresSelection) {
      cart.add(SelfOrderCartLine(item: item, quantity: 1));
      return;
    }

    final result = await OptionSelectionSheet.show(item);
    if (result == null) return;
    cart.add(
      SelfOrderCartLine(
        item: item,
        quantity: result.quantity,
        options: result.options,
        note: result.note,
      ),
    );
  }

  void removeCartLine(int index) => cart.removeAt(index);

  Future<void> submitCart() async {
    if (cart.isEmpty || isSubmitting.value) return;

    isSubmitting.value = true;
    final result = await _addItems(
      AddSelfOrderItemsParams(
        qrToken: qrToken,
        items: cart.map((line) => line.toPayload()).toList(growable: false),
      ),
    );
    isSubmitting.value = false;

    result.fold(
      onSuccess: (order) {
        currentOrder.value = order;
        cart.clear();
        AppDialogs.success('self_order_submit_success'.tr);
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }
}
