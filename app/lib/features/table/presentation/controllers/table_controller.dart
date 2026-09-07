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
    required SessionService session,
  })  : _getTables = getTables,
        _setTableStatus = setTableStatus,
        _session = session;

  final GetTablesUseCase _getTables;
  final SetTableStatusUseCase _setTableStatus;
  final SessionService _session;

  final RxList<DiningTable> tables = <DiningTable>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxnString selectedZone = RxnString();
  final RxnString selectedStatus = RxnString();

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
    return tables.where((table) {
      final zoneMatched = selectedZone.value == null || table.zone == selectedZone.value;
      final statusMatched = selectedStatus.value == null || table.status == selectedStatus.value;
      return zoneMatched && statusMatched;
    }).toList(growable: false);
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
        AppDialogs.success('อัปเดตสถานะโต๊ะ ${table.name} แล้ว');
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
        arguments: {'tableId': table.id, 'tableName': table.name, 'seats': table.seats},
      );
    }
    await loadTables(showLoader: false);
  }

  /// โต๊ะเปลี่ยนสถานะเมื่อมีคนเปิด/ปิดบิลจากเครื่องอื่น จึงต้องรีเฟรชตาม event
  void _listenToRealtimeUpdates() {
    final socket = _session.socket;
    for (final event in [
      SocketEvents.tableUpdated,
      SocketEvents.orderCreated,
      SocketEvents.orderPaid,
    ]) {
      _unsubscribers.add(socket.on(event, (_) => loadTables(showLoader: false)));
    }
  }
}
