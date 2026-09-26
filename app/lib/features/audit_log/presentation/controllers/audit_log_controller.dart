// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:get/get.dart';

import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/csv_download/csv_download.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
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
  AuditLogController({
    required GetAuditLogsUseCase getAuditLogs,
    required ExportAuditLogsUseCase exportAuditLogs,
  }) : _getAuditLogs = getAuditLogs,
       _exportAuditLogs = exportAuditLogs;

  static const int pageSize = 50;

  final GetAuditLogsUseCase _getAuditLogs;
  final ExportAuditLogsUseCase _exportAuditLogs;

  final RxList<AuditLog> logs = <AuditLog>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isExporting = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString actionFilter = RxnString();

  /// ช่วงวันที่ filter (ดู docs/tickets/14-financial-audit-trail.md) — null ทั้งคู่ = ไม่กรอง
  final Rxn<DateTime> dateFrom = Rxn<DateTime>();
  final Rxn<DateTime> dateTo = Rxn<DateTime>();

  /// จำนวนรายการทั้งหมดที่ตรงตัวกรอง (จาก meta.total ของ backend)
  final RxInt total = 0.obs;

  int _page = 1;

  bool get hasMore => logs.length < total.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  String? get _isoDateFrom =>
      dateFrom.value == null ? null : Formatters.isoDate(dateFrom.value!);
  String? get _isoDateTo =>
      dateTo.value == null ? null : Formatters.isoDate(dateTo.value!);

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    _page = 1;

    final result = await _getAuditLogs(
      AuditLogFilter(
        action: actionFilter.value,
        dateFrom: _isoDateFrom,
        dateTo: _isoDateTo,
        page: 1,
        limit: pageSize,
      ),
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
        dateFrom: _isoDateFrom,
        dateTo: _isoDateTo,
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

  /// ตั้งช่วงวันที่ filter แล้วโหลดใหม่ทันที — ส่ง null ทั้งคู่เพื่อล้าง filter
  void setDateRange(DateTime? from, DateTime? to) {
    dateFrom.value = from;
    dateTo.value = to;
    load();
  }

  String actionLabel(String action) => AuditLogAction.translationKey(action).tr;

  /// export CSV ตาม filter ปัจจุบัน (ดู docs/tickets/14-financial-audit-trail.md) —
  /// รองรับเฉพาะเว็บ (ดู core/utils/csv_download) เพราะหน้านี้อยู่ในโซนผู้ดูแลระบบซึ่งเป็นเว็บเท่านั้น
  Future<void> exportCsv() async {
    if (!isCsvDownloadSupported) {
      AppDialogs.error('audit_log_export_unsupported_platform'.tr);
      return;
    }

    isExporting.value = true;
    final result = await _exportAuditLogs(
      AuditLogFilter(
        action: actionFilter.value,
        dateFrom: _isoDateFrom,
        dateTo: _isoDateTo,
      ),
    );
    isExporting.value = false;

    result.fold(
      onSuccess: (csv) {
        downloadCsv(
          'audit-logs-${Formatters.isoDate(AppClock.now())}.csv',
          csv,
        );
      },
      onFailure: (failure) => AppDialogs.error(failure.message),
    );
  }
}
