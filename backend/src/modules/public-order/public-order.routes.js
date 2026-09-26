// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { Router } from 'express';
import { validate } from '../../middlewares/validate.js';
import { rateLimit } from '../../core/rateLimit.js';
import { publicOrderController } from './public-order.controller.js';
import { qrTokenParamSchema, addPublicItemsSchema } from './public-order.schema.js';

// ไม่มี authenticate เลยทั้งไฟล์นี้โดยตั้งใจ (ดู docs/tickets/17-qr-self-order.md) — ลูกค้าสแกน QR
// ที่โต๊ะแล้วสั่งเองได้โดยไม่ต้อง login เลย ความปลอดภัยอยู่ที่ qrToken (สุ่มไม่ซ้ำต่อโต๊ะ) แทน
const router = Router();

// จำกัดเฉพาะ endpoint ที่เขียนข้อมูล (เพิ่มรายการ) — endpoint อ่านอย่างเดียวไม่ต้องจำกัด เพราะ
// เมนู/หน้าโต๊ะรีเฟรชบ่อยได้ตามปกติ ไม่ได้เปลี่ยนสถานะอะไร
const addItemsRateLimit = rateLimit({
  windowMs: 5 * 60 * 1000,
  max: 30,
  keyFn: (req) => req.params.qrToken,
});

router.get(
  '/tables/:qrToken',
  validate({ params: qrTokenParamSchema }),
  publicOrderController.getTable,
);
router.get(
  '/tables/:qrToken/menu',
  validate({ params: qrTokenParamSchema }),
  publicOrderController.getMenu,
);
router.post(
  '/tables/:qrToken/items',
  addItemsRateLimit,
  validate({ params: qrTokenParamSchema, body: addPublicItemsSchema }),
  publicOrderController.addItems,
);

export default router;
