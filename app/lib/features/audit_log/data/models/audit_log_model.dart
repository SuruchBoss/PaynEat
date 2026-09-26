// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../domain/entities/audit_log.dart';

class AuditLogModel extends AuditLog {
  const AuditLogModel({
    required super.id,
    required super.actorName,
    required super.action,
    required super.entityType,
    required super.summary,
    required super.createdAt,
    super.actorUserId,
    super.entityId,
    super.reason,
    super.metadata,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => AuditLogModel(
    id: (json['id'] as num).toInt(),
    actorUserId: (json['actorUserId'] as num?)?.toInt(),
    actorName: json['actorName'] as String? ?? '',
    action: json['action'] as String? ?? '',
    entityType: json['entityType'] as String? ?? '',
    entityId: (json['entityId'] as num?)?.toInt(),
    summary: json['summary'] as String? ?? '',
    reason: json['reason'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
    createdAt: json['createdAt'] as String? ?? '',
  );
}
