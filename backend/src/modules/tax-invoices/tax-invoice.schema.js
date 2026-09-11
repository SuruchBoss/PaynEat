import { z } from 'zod';

export const issueTaxInvoiceSchema = z
  .object({
    invoiceType: z.enum(['abbreviated', 'full']),
    customerName: z.string().trim().min(1).max(200).optional(),
    customerAddress: z.string().trim().min(1).max(500).optional(),
    customerTaxId: z.string().trim().max(20).optional(),
  })
  .refine((data) => data.invoiceType !== 'full' || Boolean(data.customerName), {
    message: 'ใบกำกับภาษีเต็มรูปต้องระบุชื่อลูกค้า',
    path: ['customerName'],
  })
  .refine((data) => data.invoiceType !== 'full' || Boolean(data.customerAddress), {
    message: 'ใบกำกับภาษีเต็มรูปต้องระบุที่อยู่ลูกค้า',
    path: ['customerAddress'],
  });

export const voidTaxInvoiceSchema = z.object({
  reason: z.string().trim().min(1, 'กรุณาระบุเหตุผลที่ยกเลิก').max(300),
});

export const idParamSchema = z.object({ id: z.coerce.number().int().positive() });
