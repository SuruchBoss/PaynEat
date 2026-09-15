import 'package:get/get.dart';

import '../../domain/entities/audit_log.dart';
import '../../domain/entities/audit_log_action.dart';
import '../../domain/usecases/audit_log_usecases.dart';

/// ดูประวัติ audit log ทั้งหมด (admin เท่านั้น) filter ตาม action ได้
/// (ดู docs/tickets/08-audit-log.md)
class AuditLogController extends GetxController {
  AuditLogController({required GetAuditLogsUseCase getAuditLogs})
    : _getAuditLogs = getAuditLogs;

  final GetAuditLogsUseCase _getAuditLogs;

  final RxList<AuditLog> logs = <AuditLog>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxnString actionFilter = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _getAuditLogs(
      AuditLogFilter(action: actionFilter.value, limit: 100),
    );

    isLoading.value = false;
    result.fold(
      onSuccess: logs.assignAll,
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  void filterByAction(String? action) {
    actionFilter.value = action;
    load();
  }

  String actionLabel(String action) => AuditLogAction.translationKey(action).tr;
}
