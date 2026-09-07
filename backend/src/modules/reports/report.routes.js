import { Router } from 'express';
import { z } from 'zod';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { reportController } from './report.controller.js';

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

router.get('/summary', validate({ query: rangeQuerySchema }), reportController.summary);

router.get('/top-items', validate({ query: topItemQuerySchema }), reportController.topItems);

router.get('/sales-by-day', validate({ query: rangeQuerySchema }), reportController.salesByDay);

router.get('/dashboard', reportController.dashboard);

export default router;
