// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { z } from 'zod';
import { orderItemInputSchema } from '../orders/order.schema.js';

export const qrTokenParamSchema = z.object({
  // randomUUID() เสมอ (ดู table.repository.js#create) — เช็ครูปแบบตั้งแต่ชั้น validate กัน query
  // ฐานข้อมูลด้วย string ประหลาดโดยไม่จำเป็น (ไม่ใช่มาตรการความปลอดภัยหลัก แค่กรองขยะตั้งแต่ต้นทาง)
  qrToken: z.string().uuid('รูปแบบ QR ไม่ถูกต้อง'),
});

export const addPublicItemsSchema = z.object({
  items: z.array(orderItemInputSchema).min(1, 'ต้องมีอย่างน้อย 1 รายการ').max(20),
});
