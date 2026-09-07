import { z } from 'zod';

export const ORDER_STATUSES = ['open', 'in_kitchen', 'served', 'paid', 'cancelled'];
export const ORDER_ITEM_STATUSES = ['pending', 'cooking', 'ready', 'served', 'cancelled'];

const orderItemInputSchema = z.object({
  menuItemId: z.number().int().positive(),
  quantity: z.number().int().min(1, 'จำนวนต้องมากกว่า 0').max(99),
  optionIds: z.array(z.number().int().positive()).default([]),
  note: z.string().max(200).optional(),
});

export const createOrderSchema = z
  .object({
    type: z.enum(['dine_in', 'takeaway', 'delivery']).default('dine_in'),
    tableId: z.number().int().positive().optional(),
    guestCount: z.number().int().min(1).max(50).default(1),
    note: z.string().max(300).optional(),
    items: z.array(orderItemInputSchema).default([]),
  })
  .refine((data) => data.type !== 'dine_in' || data.tableId !== undefined, {
    message: 'ออเดอร์แบบทานที่ร้านต้องระบุโต๊ะ',
    path: ['tableId'],
  });

export const addItemsSchema = z.object({
  items: z.array(orderItemInputSchema).min(1, 'ต้องมีอย่างน้อย 1 รายการ'),
});

export const updateItemSchema = z.object({
  quantity: z.number().int().min(1).max(99).optional(),
  note: z.string().max(200).optional(),
});

export const updateItemStatusSchema = z.object({
  status: z.enum(ORDER_ITEM_STATUSES),
});

export const updateOrderSchema = z.object({
  guestCount: z.number().int().min(1).max(50).optional(),
  note: z.string().max(300).optional(),
});

export const discountSchema = z.object({
  type: z.enum(['none', 'amount', 'percent']),
  value: z.number().min(0).default(0),
});

export const cancelOrderSchema = z.object({
  reason: z.string().min(1, 'กรุณาระบุเหตุผลการยกเลิก').max(200),
});

export const listOrderQuerySchema = z.object({
  status: z.enum(ORDER_STATUSES).optional(),
  tableId: z.coerce.number().int().positive().optional(),
  waiterId: z.coerce.number().int().positive().optional(),
  dateFrom: z.string().optional(),
  dateTo: z.string().optional(),
  activeOnly: z
    .enum(['true', 'false'])
    .transform((v) => v === 'true')
    .optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const kitchenQuerySchema = z.object({
  status: z.string().optional(),
});

export const idParamSchema = z.object({ id: z.coerce.number().int().positive() });

export const itemParamSchema = z.object({
  id: z.coerce.number().int().positive(),
  itemId: z.coerce.number().int().positive(),
});
