// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

export const toAuditLogDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    actorUserId: row.actor_user_id,
    actorName: row.actor_name,
    action: row.action,
    entityType: row.entity_type,
    entityId: row.entity_id,
    summary: row.summary,
    reason: row.reason,
    metadata: row.metadata_json ? JSON.parse(row.metadata_json) : null,
    createdAt: row.created_at,
  };
};

export default toAuditLogDto;
