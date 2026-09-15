import { z } from 'zod';

export const createCustomerSchema = z.object({
  name: z.string().trim().min(1, 'กรุณากรอกชื่อลูกค้า').max(120),
  phone: z
    .string()
    .trim()
    .min(9, 'เบอร์โทรไม่ถูกต้อง')
    .max(20)
    .regex(/^[0-9+\-\s]+$/, 'เบอร์โทรไม่ถูกต้อง'),
  email: z.string().trim().email('อีเมลไม่ถูกต้อง').max(120).optional(),
});

export const listCustomerQuerySchema = z.object({
  search: z.string().trim().min(1).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const idParamSchema = z.object({ id: z.coerce.number().int().positive() });
