import { Router } from 'express';
import { z } from 'zod';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { asyncHandler } from '../../core/asyncHandler.js';
import { ok } from '../../core/response.js';
import { reportService } from './report.service.js';

const dateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'รูปแบบวันที่ต้องเป็น YYYY-MM-DD')
  .optional();

const rangeQuerySchema = z.object({ from: dateSchema, to: dateSchema });
const topItemQuerySchema = rangeQuerySchema.extend({
  limit: z.coerce.number().int().min(1).max(50).default(10),
});

const router = Router();
router.use(authenticate, authorize('admin', 'manager', 'cashier'));

router.get(
  '/summary',
  validate({ query: rangeQuerySchema }),
  asyncHandler(async (req, res) => ok(res, reportService.summary(req.validated.query))),
);

router.get(
  '/top-items',
  validate({ query: topItemQuerySchema }),
  asyncHandler(async (req, res) => ok(res, reportService.topItems(req.validated.query))),
);

router.get(
  '/sales-by-day',
  validate({ query: rangeQuerySchema }),
  asyncHandler(async (req, res) => ok(res, reportService.salesByDay(req.validated.query))),
);

router.get('/dashboard', asyncHandler(async (_req, res) => ok(res, reportService.dashboard())));

export default router;
