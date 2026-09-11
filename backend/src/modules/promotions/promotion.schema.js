import { z } from 'zod';

const timePattern = /^([01]\d|2[0-3]):[0-5]\d$/;

const conditionsSchema = z
  .object({
    daysOfWeek: z.array(z.number().int().min(0).max(6)).optional(),
    startTime: z.string().regex(timePattern, 'รูปแบบเวลาต้องเป็น HH:mm').optional(),
    endTime: z.string().regex(timePattern, 'รูปแบบเวลาต้องเป็น HH:mm').optional(),
    categoryIds: z.array(z.number().int().positive()).optional(),
    menuItemIds: z.array(z.number().int().positive()).optional(),
    minSubtotal: z.number().min(0).optional(),
  })
  .default({});

export const createPromotionSchema = z
  .object({
    name: z.string().min(1, 'กรุณากรอกชื่อโปรโมชัน').max(100),
    type: z.enum(['percent', 'amount', 'bogo']),
    value: z.number().min(0).default(0),
    code: z
      .string()
      .trim()
      .min(2)
      .max(30)
      .transform((value) => value.toUpperCase())
      .optional(),
    conditions: conditionsSchema,
    isActive: z.boolean().default(true),
    validFrom: z.string().optional(),
    validTo: z.string().optional(),
  })
  .refine((data) => data.type !== 'percent' || data.value <= 100, {
    message: 'ส่วนลดเปอร์เซ็นต์เกิน 100% ไม่ได้',
    path: ['value'],
  });

export const updatePromotionSchema = z
  .object({
    name: z.string().min(1).max(100).optional(),
    type: z.enum(['percent', 'amount', 'bogo']).optional(),
    value: z.number().min(0).optional(),
    code: z
      .string()
      .trim()
      .min(2)
      .max(30)
      .transform((value) => value.toUpperCase())
      .nullable()
      .optional(),
    conditions: conditionsSchema.optional(),
    isActive: z.boolean().optional(),
    validFrom: z.string().nullable().optional(),
    validTo: z.string().nullable().optional(),
  })
  .refine((data) => data.type !== 'percent' || data.value === undefined || data.value <= 100, {
    message: 'ส่วนลดเปอร์เซ็นต์เกิน 100% ไม่ได้',
    path: ['value'],
  });

export const listPromotionQuerySchema = z.object({
  activeOnly: z
    .enum(['true', 'false'])
    .transform((value) => value === 'true')
    .optional(),
});

export const redeemPromotionCodeSchema = z.object({
  code: z.string().trim().min(1, 'กรุณากรอกโค้ดส่วนลด'),
});

export const idParamSchema = z.object({ id: z.coerce.number().int().positive() });
