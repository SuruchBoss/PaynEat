import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/audit_log.dart';
import '../repositories/audit_log_repository.dart';

/// ตัวกรองสำหรับหน้าจอ audit log ของ admin (ดู docs/tickets/08-audit-log.md
/// — "filter ตามผู้ใช้/ช่วงเวลา/ประเภท")
class AuditLogFilter {
  const AuditLogFilter({
    this.actorUserId,
    this.action,
    this.entityType,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 50,
  });

  final int? actorUserId;
  final String? action;
  final String? entityType;
  final String? dateFrom;
  final String? dateTo;
  final int page;
  final int limit;
}

class GetAuditLogsUseCase
    implements UseCase<({List<AuditLog> logs, int total}), AuditLogFilter> {
  const GetAuditLogsUseCase(this._repository);

  final AuditLogRepository _repository;

  @override
  Future<Result<({List<AuditLog> logs, int total})>> call(
    AuditLogFilter params,
  ) => _repository.list(
    actorUserId: params.actorUserId,
    action: params.action,
    entityType: params.entityType,
    dateFrom: params.dateFrom,
    dateTo: params.dateTo,
    page: params.page,
    limit: params.limit,
  );
}

/// export audit log เป็น CSV ตาม filter เดียวกับหน้าจอ (ดู
/// docs/tickets/14-financial-audit-trail.md) — ไม่มี page/limit เพราะดึงทุกแถวที่ตรงเงื่อนไข
class ExportAuditLogsUseCase implements UseCase<String, AuditLogFilter> {
  const ExportAuditLogsUseCase(this._repository);

  final AuditLogRepository _repository;

  @override
  Future<Result<String>> call(AuditLogFilter params) => _repository.exportCsv(
    actorUserId: params.actorUserId,
    action: params.action,
    entityType: params.entityType,
    dateFrom: params.dateFrom,
    dateTo: params.dateTo,
  );
}
