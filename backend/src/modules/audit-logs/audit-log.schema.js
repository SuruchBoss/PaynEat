// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { z } from 'zod';

const auditLogFiltersSchema = {
  actorUserId: z.coerce.number().int().positive().optional(),
  action: z.string().trim().min(1).optional(),
  entityType: z.string().trim().min(1).optional(),
  entityId: z.coerce.number().int().positive().optional(),
  dateFrom: z.string().optional(),
  dateTo: z.string().optional(),
};

export const listAuditLogQuerySchema = z.object({
  ...auditLogFiltersSchema,
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const exportAuditLogQuerySchema = z.object(auditLogFiltersSchema);
