import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created } from '../../core/response.js';
import { paymentService } from './payment.service.js';
import { createPaymentSchema, idParamSchema } from './payment.schema.js';

const router = Router();
router.use(authenticate);

const cashier = authorize('admin', 'manager', 'cashier', 'waiter');

router.post(
  '/',
  cashier,
  validate({ body: createPaymentSchema }),
  asyncHandler(async (req, res) => created(res, paymentService.pay(req.body, req.user))),
);

router.get(
  '/order/:id',
  validate({ params: idParamSchema }),
  asyncHandler(async (req, res) => ok(res, paymentService.summary(req.validated.params.id))),
);

router.get(
  '/order/:id/receipt',
  validate({ params: idParamSchema }),
  asyncHandler(async (req, res) => ok(res, paymentService.receipt(req.validated.params.id))),
);

export default router;
