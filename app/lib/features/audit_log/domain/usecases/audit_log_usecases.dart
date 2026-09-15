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
    this.limit = 50,
  });

  final int? actorUserId;
  final String? action;
  final String? entityType;
  final String? dateFrom;
  final String? dateTo;
  final int limit;
}

class GetAuditLogsUseCase implements UseCase<List<AuditLog>, AuditLogFilter> {
  const GetAuditLogsUseCase(this._repository);

  final AuditLogRepository _repository;

  @override
  Future<Result<List<AuditLog>>> call(AuditLogFilter params) =>
      _repository.list(
        actorUserId: params.actorUserId,
        action: params.action,
        entityType: params.entityType,
        dateFrom: params.dateFrom,
        dateTo: params.dateTo,
        limit: params.limit,
      );
}
