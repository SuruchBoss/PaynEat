import '../../../../core/usecases/result.dart';
import '../entities/audit_log.dart';

abstract class AuditLogRepository {
  Future<Result<({List<AuditLog> logs, int total})>> list({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 50,
  });
}
