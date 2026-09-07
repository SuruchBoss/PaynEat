import { z } from 'zod';

export const TABLE_STATUSES = ['available', 'occupied', 'reserved', 'billing'];

export const createTableSchema = z.object({
  name: z.string().min(1, 'กรุณากรอกชื่อโต๊ะ').max(20),
  zone: z.string().max(40).optional(),
  seats: z.number().int().min(1).max(50).optional(),
});

export const updateTableSchema = createTableSchema.partial().extend({
  status: z.enum(TABLE_STATUSES).optional(),
  isActive: z.boolean().optional(),
});

export const setStatusSchema = z.object({
  status: z.enum(TABLE_STATUSES),
});

export const listTableQuerySchema = z.object({
  zone: z.string().max(40).optional(),
  status: z.enum(TABLE_STATUSES).optional(),
});

export const idParamSchema = z.object({ id: z.coerce.number().int().positive() });
