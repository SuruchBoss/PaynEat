import { z } from 'zod';

export const ROLES = ['admin', 'manager', 'waiter', 'cashier', 'kitchen'];

export const createUserSchema = z.object({
  name: z.string().min(2, 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร').max(80),
  username: z
    .string()
    .min(3, 'username ต้องมีอย่างน้อย 3 ตัวอักษร')
    .max(40)
    .regex(/^[a-zA-Z0-9_.-]+$/, 'username ใช้ได้เฉพาะ a-z 0-9 . _ -'),
  password: z.string().min(6, 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร').max(72),
  role: z.enum(ROLES),
});

export const updateUserSchema = z.object({
  name: z.string().min(2).max(80).optional(),
  role: z.enum(ROLES).optional(),
  isActive: z.boolean().optional(),
});

export const resetPasswordSchema = z.object({
  password: z.string().min(6).max(72),
});

export const listUserQuerySchema = z.object({
  role: z.enum(ROLES).optional(),
  isActive: z
    .enum(['true', 'false'])
    .transform((value) => value === 'true')
    .optional(),
});

export const idParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});
