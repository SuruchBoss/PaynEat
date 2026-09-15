import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/audit_log_model.dart';

abstract class AuditLogRemoteDataSource {
  Future<List<AuditLogModel>> list({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
    int limit = 50,
  });
}

class AuditLogRemoteDataSourceImpl implements AuditLogRemoteDataSource {
  const AuditLogRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<AuditLogModel>> list({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
    int limit = 50,
  }) async {
    final result = await _client.get(
      ApiEndpoints.auditLogs,
      query: {
        'actorUserId': actorUserId,
        'action': action,
        'entityType': entityType,
        'dateFrom': dateFrom,
        'dateTo': dateTo,
        'limit': limit,
      },
    );
    return result.asList.map(AuditLogModel.fromJson).toList(growable: false);
  }
}
