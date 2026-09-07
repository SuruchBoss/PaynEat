import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { paymentController } from './payment.controller.js';
import { createPaymentSchema, idParamSchema } from './payment.schema.js';

const router = Router();
router.use(authenticate);

const cashier = authorize('admin', 'manager', 'cashier', 'waiter');

router.post('/', cashier, validate({ body: createPaymentSchema }), paymentController.pay);

router.get('/order/:id', validate({ params: idParamSchema }), paymentController.summary);

router.get('/order/:id/receipt', validate({ params: idParamSchema }), paymentController.receipt);

export default router;
