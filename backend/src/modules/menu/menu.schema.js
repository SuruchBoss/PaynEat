import { z } from 'zod';

const optionSchema = z.object({
  name: z.string().min(1).max(60),
  priceDelta: z.number().min(0).default(0),
  isDefault: z.boolean().optional(),
});

const optionGroupSchema = z.object({
  name: z.string().min(1).max(60),
  minSelect: z.number().int().min(0).default(0),
  maxSelect: z.number().int().min(1).default(1),
  isRequired: z.boolean().default(false),
  options: z.array(optionSchema).min(1, 'กลุ่มตัวเลือกต้องมีอย่างน้อย 1 ตัวเลือก'),
});

const ingredientLinkSchema = z.object({
  ingredientId: z.number().int().positive(),
  qtyPerUnit: z.number().positive(),
});

const ingredientLinksSchema = z
  .array(ingredientLinkSchema)
  .optional()
  .refine(
    (links) => !links || new Set(links.map((link) => link.ingredientId)).size === links.length,
    { message: 'เลือกวัตถุดิบซ้ำกันในเมนูเดียวไม่ได้' },
  );

export const createMenuItemSchema = z.object({
  categoryId: z.number().int().positive(),
  name: z.string().min(1, 'กรุณากรอกชื่อเมนู').max(120),
  nameEn: z.string().max(120).optional(),
  description: z.string().max(500).optional(),
  price: z.number().min(0, 'ราคาต้องไม่ติดลบ'),
  imageUrl: z.string().url('รูปแบบ URL ไม่ถูกต้อง').optional().or(z.literal('')),
  isAvailable: z.boolean().optional(),
  isRecommended: z.boolean().optional(),
  prepMinutes: z.number().int().min(0).max(240).optional(),
  sortOrder: z.number().int().min(0).optional(),
  optionGroups: z.array(optionGroupSchema).optional(),
  ingredients: ingredientLinksSchema,
});

export const updateMenuItemSchema = createMenuItemSchema.partial();

export const toggleAvailabilitySchema = z.object({
  isAvailable: z.boolean(),
});

export const listMenuQuerySchema = z.object({
  categoryId: z.coerce.number().int().positive().optional(),
  search: z.string().max(120).optional(),
  availableOnly: z
    .enum(['true', 'false'])
    .transform((v) => v === 'true')
    .optional(),
  recommendedOnly: z
    .enum(['true', 'false'])
    .transform((v) => v === 'true')
    .optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(200).default(100),
});

export const idParamSchema = z.object({ id: z.coerce.number().int().positive() });
