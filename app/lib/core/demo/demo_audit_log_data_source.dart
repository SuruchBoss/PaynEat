// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

part of 'demo_data_sources.dart';

class DemoAuditLogDataSource implements AuditLogRemoteDataSource {
  const DemoAuditLogDataSource(this._store);

  final DemoStore _store;

  @override
  Future<({List<AuditLogModel> logs, int total})> list({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 50,
  }) => _delayed(() {
    final result = _store.auditLogList(
      actorUserId: actorUserId,
      action: action,
      entityType: entityType,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
      limit: limit,
    );
    return (
      logs: result.rows.map(AuditLogModel.fromJson).toList(growable: false),
      total: result.total,
    );
  });

  @override
  Future<String> exportCsv({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
  }) => _delayed(
    () => _store.auditLogExportCsv(
      actorUserId: actorUserId,
      action: action,
      entityType: entityType,
      dateFrom: dateFrom,
      dateTo: dateTo,
    ),
  );
}
