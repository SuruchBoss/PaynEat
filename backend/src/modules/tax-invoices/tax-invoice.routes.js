import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { taxInvoiceController } from './tax-invoice.controller.js';
import {
  issueTaxInvoiceSchema,
  voidTaxInvoiceSchema,
  idParamSchema,
} from './tax-invoice.schema.js';

const router = Router();
router.use(authenticate);

const cashier = authorize('admin', 'manager', 'cashier', 'waiter');
const manager = authorize('admin', 'manager');

router.get('/order/:id', validate({ params: idParamSchema }), taxInvoiceController.detail);

router.post(
  '/order/:id',
  cashier,
  validate({ params: idParamSchema, body: issueTaxInvoiceSchema }),
  taxInvoiceController.issue,
);

router.post(
  '/order/:id/void',
  manager,
  validate({ params: idParamSchema, body: voidTaxInvoiceSchema }),
  taxInvoiceController.void,
);

export default router;
