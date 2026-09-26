// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/audit_log_remote_data_source.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  const AuditLogRepositoryImpl(this._remote);

  final AuditLogRemoteDataSource _remote;

  @override
  Future<Result<({List<AuditLog> logs, int total})>> list({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 50,
  }) => guard(
    () => _remote.list(
      actorUserId: actorUserId,
      action: action,
      entityType: entityType,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
      limit: limit,
    ),
  );

  @override
  Future<Result<String>> exportCsv({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
  }) => guard(
    () => _remote.exportCsv(
      actorUserId: actorUserId,
      action: action,
      entityType: entityType,
      dateFrom: dateFrom,
      dateTo: dateTo,
    ),
  );
}
