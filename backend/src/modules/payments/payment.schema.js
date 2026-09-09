import { z } from 'zod';

export const PAYMENT_METHODS = ['cash', 'qr', 'card', 'transfer'];

export const createPaymentSchema = z
  .object({
    orderId: z.number().int().positive(),
    method: z.enum(PAYMENT_METHODS),
    // ระบุอย่างใดอย่างหนึ่ง: amount (จ่ายเป็นจำนวนเงิน) หรือ itemIds (แยกบิลรายการอาหาร
    // — ระบบคำนวณยอดที่ต้องจ่ายเองจากรายการที่เลือก ไม่รับยอดจากไคลเอนต์เพื่อกันการโกงยอด)
    amount: z.number().min(0.01, 'ยอดชำระต้องมากกว่า 0').optional(),
    itemIds: z.array(z.number().int().positive()).min(1, 'ต้องเลือกอย่างน้อย 1 รายการ').optional(),
    received: z.number().min(0).optional(),
    reference: z.string().max(80).optional(),
  })
  .refine((data) => data.itemIds?.length || data.amount !== undefined, {
    message: 'ต้องระบุ amount หรือ itemIds อย่างใดอย่างหนึ่ง',
    path: ['amount'],
  })
  .refine(
    (data) =>
      data.itemIds?.length || data.method !== 'cash' || (data.received ?? 0) >= (data.amount ?? 0),
    {
      message: 'เงินที่รับมาต้องไม่น้อยกว่ายอดที่ชำระ',
      path: ['received'],
    },
  );

export const splitPreviewSchema = z.object({
  itemIds: z.array(z.number().int().positive()).min(1, 'ต้องเลือกอย่างน้อย 1 รายการ'),
});

export const idParamSchema = z.object({ id: z.coerce.number().int().positive() });

export const createRefundSchema = z.object({
  amount: z.number().min(0.01, 'ยอดคืนต้องมากกว่า 0'),
  reason: z.string().min(1, 'กรุณาระบุเหตุผลที่คืนเงิน').max(300),
});
