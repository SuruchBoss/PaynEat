// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

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

// ตั้งค่าลูกค้าเครดิต (ดู docs/tickets/20-b2b-credit.md) — ส่งครบทุกช่องเสมอ (เป็นฟอร์มเดียวกันในแอป)
// taxId/address ส่ง '' เพื่อล้างค่า
export const updateCreditSchema = z.object({
  creditLimit: z.number().min(0, 'วงเงินต้องไม่ติดลบ').max(100_000_000),
  creditTermDays: z.number().int().min(0).max(365, 'เครดิตเทอมต้องไม่เกิน 365 วัน'),
  taxId: z
    .string()
    .trim()
    .regex(/^\d{13}$/, 'เลขประจำตัวผู้เสียภาษีต้องเป็นตัวเลข 13 หลัก')
    .optional()
    .or(z.literal('')),
  address: z.string().trim().max(300).optional(),
  // อีเมลรับใบวางบิล/เอกสารลูกหนี้ (docs/tickets/23-document-pdf-email.md) — ไม่ส่งมา = คงค่าเดิม
  // (แอปรุ่นก่อนไม่มีช่องนี้) ส่ง '' = ล้างค่า
  email: z.string().trim().email('อีเมลไม่ถูกต้อง').max(120).optional().or(z.literal('')),
});

export const idParamSchema = z.object({ id: z.coerce.number().int().positive() });
