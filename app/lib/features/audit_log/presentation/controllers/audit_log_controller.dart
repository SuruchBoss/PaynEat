import 'package:get/get.dart';

import '../../domain/entities/audit_log.dart';
import '../../domain/entities/audit_log_action.dart';
import '../../domain/usecases/audit_log_usecases.dart';

/// ดูประวัติ audit log ทั้งหมด (admin เท่านั้น) filter ตาม action ได้
/// (ดู docs/tickets/08-audit-log.md)
///
/// โหลดทีละหน้า เพราะ backend จำกัด limit ไว้ที่ 100 ต่อครั้ง (audit-log.schema.js)
/// ถ้าดึงครั้งเดียวแล้วจบ ผู้ใช้จะเห็นแค่ 100 รายการล่าสุดโดยไม่รู้ว่ายังมีต่อ —
/// หน้านี้มีไว้สืบเหตุการณ์ย้อนหลัง การตัดเงียบ ๆ ทำให้สรุปผิดว่า "ไม่มี"
class AuditLogController extends GetxController {
  AuditLogController({required GetAuditLogsUseCase getAuditLogs})
    : _getAuditLogs = getAuditLogs;

  static const int pageSize = 50;

  final GetAuditLogsUseCase _getAuditLogs;

  final RxList<AuditLog> logs = <AuditLog>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString actionFilter = RxnString();

  /// จำนวนรายการทั้งหมดที่ตรงตัวกรอง (จาก meta.total ของ backend)
  final RxInt total = 0.obs;

  int _page = 1;

  bool get hasMore => logs.length < total.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    _page = 1;

    final result = await _getAuditLogs(
      AuditLogFilter(action: actionFilter.value, page: 1, limit: pageSize),
    );

    isLoading.value = false;
    result.fold(
      onSuccess: (data) {
        logs.assignAll(data.logs);
        total.value = data.total;
      },
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  /// ต่อท้ายหน้าถัดไป — ไม่ล้างของเดิม เพื่อให้เลื่อนอ่านต่อได้ไม่สะดุด
  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore) return;
    isLoadingMore.value = true;

    final result = await _getAuditLogs(
      AuditLogFilter(
        action: actionFilter.value,
        page: _page + 1,
        limit: pageSize,
      ),
    );

    isLoadingMore.value = false;
    result.fold(
      onSuccess: (data) {
        _page += 1;
        logs.addAll(data.logs);
        total.value = data.total;
      },
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  void filterByAction(String? action) {
    actionFilter.value = action;
    load();
  }

  String actionLabel(String action) => AuditLogAction.translationKey(action).tr;
}
