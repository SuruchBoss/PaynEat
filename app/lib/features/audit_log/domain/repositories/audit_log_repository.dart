import '../../../../core/usecases/result.dart';
import '../entities/audit_log.dart';

abstract class AuditLogRepository {
  Future<Result<List<AuditLog>>> list({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
    int limit = 50,
  });
}
