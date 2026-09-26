// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { z } from 'zod';

export const createIngredientSchema = z.object({
  name: z.string().min(1, 'กรุณากรอกชื่อวัตถุดิบ').max(120),
  unit: z.string().min(1, 'กรุณากรอกหน่วยนับ').max(30),
  currentStock: z.number().min(0).default(0),
  lowStockThreshold: z.number().min(0).default(0),
  // ใช้เฉพาะตอนผู้สร้างเป็น admin ในโหมด "ทุกสาขา" (ดู docs/DECISIONS.md #36)
  branchId: z.number().int().positive().optional(),
});

// currentStock ไม่แก้ผ่านช่องทางนี้โดยตรง — ต้องผ่าน /ingredients/:id/adjust-stock เท่านั้น
// เพื่อให้การเปลี่ยนสต๊อกทุกครั้งเดินผ่าน logic เดียว (sync สถานะเมนูที่เกี่ยวข้องด้วยเสมอ)
export const updateIngredientSchema = z.object({
  name: z.string().min(1).max(120).optional(),
  unit: z.string().min(1).max(30).optional(),
  lowStockThreshold: z.number().min(0).optional(),
});

export const adjustStockSchema = z.object({
  delta: z.number().refine((value) => value !== 0, 'จำนวนที่ปรับต้องไม่เป็นศูนย์'),
  note: z.string().max(200).optional(),
});

export const listIngredientQuerySchema = z.object({
  lowStockOnly: z
    .enum(['true', 'false'])
    .transform((value) => value === 'true')
    .optional(),
});

export const idParamSchema = z.object({ id: z.coerce.number().int().positive() });
