import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { paymentController } from './payment.controller.js';
import {
  createPaymentSchema,
  splitPreviewSchema,
  createRefundSchema,
  idParamSchema,
} from './payment.schema.js';

const router = Router();
router.use(authenticate);

const cashier = authorize('admin', 'manager', 'cashier', 'waiter');
const manager = authorize('admin', 'manager');

router.post('/', cashier, validate({ body: createPaymentSchema }), paymentController.pay);

router.post(
  '/:id/refund',
  manager,
  validate({ params: idParamSchema, body: createRefundSchema }),
  paymentController.refund,
);

router.post(
  '/order/:id/split-preview',
  cashier,
  validate({ params: idParamSchema, body: splitPreviewSchema }),
  paymentController.splitPreview,
);

router.get('/order/:id', validate({ params: idParamSchema }), paymentController.summary);

router.get('/order/:id/receipt', validate({ params: idParamSchema }), paymentController.receipt);

export default router;
