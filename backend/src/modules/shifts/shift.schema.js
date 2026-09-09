import { z } from 'zod';

export const openShiftSchema = z.object({
  openingCash: z.number().min(0, 'เงินตั้งต้นต้องไม่ติดลบ'),
});

export const closeShiftSchema = z.object({
  countedCash: z.number().min(0, 'ยอดเงินที่นับต้องไม่ติดลบ'),
  note: z.string().max(300).optional(),
});

export const listShiftQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

export const idParamSchema = z.object({ id: z.coerce.number().int().positive() });
