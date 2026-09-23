import { z } from 'zod';

// ช่องทางรับชำระหนี้ — ไม่มี 'credit' (จ่ายหนี้ด้วยการเชื่อเพิ่มไม่ได้)
export const RECEIPT_METHODS = ['cash', 'qr', 'card', 'transfer'];

export const createReceiptSchema = z.object({
  customerId: z.number().int().positive(),
  amount: z.number().min(0.01, 'ยอดรับชำระต้องมากกว่า 0'),
  method: z.enum(RECEIPT_METHODS),
  reference: z.string().trim().max(80).optional(),
  note: z.string().trim().max(300).optional(),
  // รับชำระตามใบวางบิลที่ลูกค้าถือมา — ตัดเฉพาะบิลในใบนั้น (ไม่ระบุ = ตัดบิลเก่าสุดก่อน)
  billingNoteId: z.number().int().positive().optional(),
});

export const createBillingNoteSchema = z.object({
  customerId: z.number().int().positive(),
  paymentIds: z.array(z.number().int().positive()).min(1).optional(),
  dueDate: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'วันนัดชำระต้องอยู่ในรูปแบบ YYYY-MM-DD')
    .optional(),
  note: z.string().trim().max(300).optional(),
});

export const voidSchema = z.object({
  reason: z.string().trim().min(1, 'กรุณาระบุเหตุผลที่ยกเลิก').max(300),
});

export const idParamSchema = z.object({ id: z.coerce.number().int().positive() });
