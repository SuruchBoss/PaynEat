import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/socket_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/dining_table.dart';
import '../../domain/usecases/table_usecases.dart';

/// จัดการหน้าผังโต๊ะ — โหลดรายการโต๊ะ กรองตามโซน และอัปเดตอัตโนมัติผ่าน socket
class TableController extends GetxController {
  TableController({
    required GetTablesUseCase getTables,
    required SetTableStatusUseCase setTableStatus,
    required RegenerateTableQrTokenUseCase regenerateQrToken,
    required SessionService session,
  }) : _getTables = getTables,
       _setTableStatus = setTableStatus,
       _regenerateQrToken = regenerateQrToken,
       _session = session;

  final GetTablesUseCase _getTables;
  final SetTableStatusUseCase _setTableStatus;
  final RegenerateTableQrTokenUseCase _regenerateQrToken;
  final SessionService _session;

  final RxList<DiningTable> tables = <DiningTable>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxnString selectedZone = RxnString();
  final RxnString selectedStatus = RxnString();
  final RxBool isRegeneratingQr = false.obs;

  /// เฉพาะ admin/manager ที่ backend อนุญาตให้เปลี่ยน QR ได้ (ดู table.routes.js) — ฝั่ง UI
  /// ซ่อนปุ่มไว้ก่อนเพื่อไม่ให้พนักงานเสิร์ฟ/แคชเชียร์กดแล้วเจอ 403 เฉยๆ
  bool get canManageQrToken =>
      _session.currentUser?.role == UserRole.admin ||
      _session.currentUser?.role == UserRole.manager;

  final List<VoidCallback> _unsubscribers = [];

  @override
  void onInit() {
    super.onInit();
    loadTables();
    _listenToRealtimeUpdates();
  }

  @override
  void onClose() {
    for (final unsubscribe in _unsubscribers) {
      unsubscribe();
    }
    super.onClose();
  }

  /// โต๊ะทุกโซนที่มีอยู่ (ใช้ทำแถบตัวกรอง)
  List<String> get zones {
    final unique = tables.map((table) => table.zone).toSet().toList()..sort();
    return unique;
  }

  List<DiningTable> get filteredTables {
    return tables
        .where((table) {
          final zoneMatched =
              selectedZone.value == null || table.zone == selectedZone.value;
          final statusMatched =
              selectedStatus.value == null ||
              table.status == selectedStatus.value;
          return zoneMatched && statusMatched;
        })
        .toList(growable: false);
  }

  int get availableCount =>
      tables.where((table) => table.status == TableStatus.available).length;
  int get occupiedCount =>
      tables.where((table) => table.status == TableStatus.occupied).length;

  Future<void> loadTables({bool showLoader = true}) async {
    if (showLoader) isLoading.value = true;
    errorMessage.value = null;

    final result = await _getTables(const TableFilter());

    isLoading.value = false;
    result.fold(
      onSuccess: tables.assignAll,
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  void filterByZone(String? zone) => selectedZone.value = zone;

  void filterByStatus(String? status) => selectedStatus.value = status;

  Future<void> changeStatus(DiningTable table, String status) async {
    final result = await _setTableStatus(
      SetTableStatusParams(id: table.id, status: status),
    );

    result.fold(
      onSuccess: (_) {
        AppDialogs.success(
          'table_status_updated_success'.trParams({'name': table.name}),
        );
        loadTables(showLoader: false);
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  /// แตะที่โต๊ะ: ว่าง → เปิดออเดอร์ใหม่, ไม่ว่าง → เปิดออเดอร์เดิม
  Future<void> openTable(DiningTable table) async {
    if (table.hasOpenOrder) {
      await Get.toNamed<void>(
        AppRoutes.orderDetail,
        arguments: {'orderId': table.currentOrder!.id},
      );
    } else {
      await Get.toNamed<void>(
        AppRoutes.newOrder,
        arguments: {
          'tableId': table.id,
          'tableName': table.name,
          'seats': table.seats,
        },
      );
    }
    await loadTables(showLoader: false);
  }

  /// เปลี่ยน QR token ของโต๊ะ (ดู docs/tickets/17-qr-self-order.md) — ต้องยืนยันก่อนเสมอเพราะ
  /// QR เดิมที่พิมพ์/แปะไว้ที่โต๊ะจะใช้ไม่ได้ทันที
  Future<void> regenerateQrToken(DiningTable table) async {
    final confirmed = await AppDialogs.confirm(
      title: 'table_qr_regenerate_confirm_title'.tr,
      message: 'table_qr_regenerate_confirm_message'.trParams({
        'name': table.name,
      }),
      confirmLabel: 'table_qr_regenerate_button'.tr,
      destructive: true,
    );
    if (!confirmed) return;

    isRegeneratingQr.value = true;
    final result = await _regenerateQrToken(table.id);
    isRegeneratingQr.value = false;

    result.fold(
      onSuccess: (updated) {
        final index = tables.indexWhere((row) => row.id == updated.id);
        if (index != -1) tables[index] = updated;
        AppDialogs.success('table_qr_regenerate_success'.tr);
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }

  /// โต๊ะเปลี่ยนสถานะเมื่อมีคนเปิด/ปิดบิลจากเครื่องอื่น จึงต้องรีเฟรชตาม event
  void _listenToRealtimeUpdates() {
    final socket = _session.socket;
    for (final event in [
      SocketEvents.tableUpdated,
      SocketEvents.orderCreated,
      SocketEvents.orderPaid,
    ]) {
      _unsubscribers.add(
        socket.on(event, (_) => loadTables(showLoader: false)),
      );
    }
  }
}
