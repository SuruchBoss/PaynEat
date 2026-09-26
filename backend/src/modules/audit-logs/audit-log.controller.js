// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { asyncHandler } from '../../core/asyncHandler.js';
import { paginated } from '../../core/response.js';
import { auditLogService } from './audit-log.service.js';

export const auditLogController = {
  list: asyncHandler(async (req, res) => {
    const query = req.validated.query;
    const { items, total } = auditLogService.list(query);
    return paginated(res, items, { page: query.page, limit: query.limit, total });
  }),

  export: asyncHandler(async (req, res) => {
    const csv = auditLogService.exportCsv(req.validated.query);
    res.status(200);
    res.set('Content-Type', 'text/csv; charset=utf-8');
    res.set('Content-Disposition', 'attachment; filename="audit-logs.csv"');
    res.send(csv);
  }),
};

export default auditLogController;
