// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/audit_log_model.dart';

abstract class AuditLogRemoteDataSource {
  Future<({List<AuditLogModel> logs, int total})> list({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 50,
  });

  /// export CSV ตาม filter เดียวกับ [list] แต่ไม่มี pagination — คืนเนื้อหาไฟล์เป็น String ดิบ
  /// (ดู docs/tickets/14-financial-audit-trail.md)
  Future<String> exportCsv({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
  });
}

class AuditLogRemoteDataSourceImpl implements AuditLogRemoteDataSource {
  const AuditLogRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<({List<AuditLogModel> logs, int total})> list({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
    int page = 1,
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
        'page': page,
        'limit': limit,
      },
    );
    return (
      logs: result.asList.map(AuditLogModel.fromJson).toList(growable: false),
      total: result.total,
    );
  }

  @override
  Future<String> exportCsv({
    int? actorUserId,
    String? action,
    String? entityType,
    String? dateFrom,
    String? dateTo,
  }) => _client.getText(
    ApiEndpoints.auditLogsExport,
    query: {
      'actorUserId': actorUserId,
      'action': action,
      'entityType': entityType,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
    },
  );
}
