import { z } from 'zod';

export const PAYMENT_METHODS = ['cash', 'qr', 'card', 'transfer'];

export const createPaymentSchema = z
  .object({
    orderId: z.number().int().positive(),
    method: z.enum(PAYMENT_METHODS),
    amount: z.number().min(0.01, 'ยอดชำระต้องมากกว่า 0'),
    received: z.number().min(0).optional(),
    reference: z.string().max(80).optional(),
  })
  .refine((data) => data.method !== 'cash' || (data.received ?? 0) >= data.amount, {
    message: 'เงินที่รับมาต้องไม่น้อยกว่ายอดที่ชำระ',
    path: ['received'],
  });

export const idParamSchema = z.object({ id: z.coerce.number().int().positive() });
