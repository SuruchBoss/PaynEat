// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { Router } from 'express';
import { asyncHandler } from '../../core/asyncHandler.js';
import { ok } from '../../core/response.js';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { scaleService } from './scale.service.js';

const router = Router();

// น้ำหนักล่าสุดจากตาชั่งต่อสาย — ทุกคนที่รับออเดอร์/เก็บเงินได้ (ครัวไม่ใช้) แอปเรียกครั้งแรกตอนเปิดกล่อง
// ชั่งน้ำหนัก แล้วฟัง socket event scale:reading ต่อ (docs/tickets/22-live-scale-camera-scan.md)
router.get(
  '/',
  authenticate,
  authorize('admin', 'manager', 'cashier', 'waiter'),
  asyncHandler(async (req, res) => ok(res, scaleService.status())),
);

export default router;
