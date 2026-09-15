import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/audit_log_remote_data_source.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  const AuditLogRepositoryImpl(this._remote);

  final AuditLogRemoteDataSource _remote;

  @override
  Future<Result<List<AuditLog>>> list({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
    int limit = 50,
  }) => guard(
    () => _remote.list(
      actorUserId: actorUserId,
      action: action,
      entityType: entityType,
      dateFrom: dateFrom,
      dateTo: dateTo,
      limit: limit,
    ),
  );
}
