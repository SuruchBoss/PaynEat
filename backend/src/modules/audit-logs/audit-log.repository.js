// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { getDb } from '../../db/index.js';

/** สร้างเงื่อนไข WHERE ร่วมกันระหว่าง list (มี pagination) กับ export (ไม่มี pagination) */
const buildWhere = ({ actorUserId, action, entityType, entityId, dateFrom, dateTo }) => {
  const clauses = [];
  const params = [];

  if (actorUserId) {
    clauses.push('actor_user_id = ?');
    params.push(actorUserId);
  }
  if (action) {
    clauses.push('action = ?');
    params.push(action);
  }
  if (entityType) {
    clauses.push('entity_type = ?');
    params.push(entityType);
  }
  if (entityId) {
    clauses.push('entity_id = ?');
    params.push(entityId);
  }
  if (dateFrom) {
    clauses.push('date(created_at) >= date(?)');
    params.push(dateFrom);
  }
  if (dateTo) {
    clauses.push('date(created_at) <= date(?)');
    params.push(dateTo);
  }

  return { where: clauses.length ? `WHERE ${clauses.join(' AND ')}` : '', params };
};

export const auditLogRepository = {
  create({ actorUserId, actorName, action, entityType, entityId, summary, reason, metadata }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO audit_logs (
          actor_user_id, actor_name, action, entity_type, entity_id, summary, reason, metadata_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `,
      )
      .run(
        actorUserId ?? null,
        actorName,
        action,
        entityType,
        entityId ?? null,
        summary,
        reason ?? null,
        metadata ? JSON.stringify(metadata) : null,
      );
    return getDb().prepare('SELECT * FROM audit_logs WHERE id = ?').get(info.lastInsertRowid);
  },

  findAll({ page = 1, limit = 20, ...filters } = {}) {
    const { where, params } = buildWhere(filters);
    const db = getDb();
    const total = db.prepare(`SELECT COUNT(*) AS c FROM audit_logs ${where}`).get(...params).c;
    const rows = db
      .prepare(`SELECT * FROM audit_logs ${where} ORDER BY id DESC LIMIT ? OFFSET ?`)
      .all(...params, limit, (page - 1) * limit);

    return { rows, total };
  },

  /** ไม่มี pagination — ใช้สำหรับ export CSV ให้ฝ่ายบัญชีเท่านั้น (ดู
   * docs/tickets/14-financial-audit-trail.md) ต่างจาก findAll ที่ใช้กับหน้าจอ list */
  findAllForExport(filters = {}) {
    const { where, params } = buildWhere(filters);
    return getDb()
      .prepare(`SELECT * FROM audit_logs ${where} ORDER BY id DESC`)
      .all(...params);
  },
};

export default auditLogRepository;
